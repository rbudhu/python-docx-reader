from string import strip
from zipfile import ZipFile
from lxml import etree


class Paragraph(object):
    """Stores the text and any graphics of a paragraph
    Graphics is a list of dict where the elements of the dict are the
    name of the graphic and its location in the media folder of the
    unzipped document"""
    def __init__(self, text=None, graphics=[]):
        self.text = text
        self.graphics = graphics


class Document(object):
    """Main representation of the document"""
    def __init__(self, path):
        self.zip_document = ZipFile(path, 'r')
        self.relationships = self.extract_relationships()
        # Extra namespaces that are not included in lxml's nsmap
        self.extra_namespaces = {
            'pic':
                'http://schemas.openxmlformats.org/drawingml/2006/picture',
            'a':
                'http://schemas.openxmlformats.org/drawingml/2006/main',
            }

    def extract_relationships(self):
        """Extracts relationships between parts
        and stores in lookup dictionary

        http://msdn.microsoft.com/en-us/library/aa982683%28v=office.12%29.aspx
        """
        relationships = {}
        with self.zip_document.open('word/_rels/document.xml.rels') as f:
            try:
                rels = etree.parse(f)
                root = rels.getroot()
                children = root.getchildren()
                for child in children:
                    id = child.get('Id')
                    media = child.get('Target')
                    relationships[id] = {'media': media}
            except Exception as e:
                print(e)
        return relationships

    @property
    def paragraphs(self):
        """Returns a generator of paragraphs"""
        with self.zip_document.open('word/document.xml') as f:
            document = etree.parse(f)
            ns = document.getroot().nsmap
            ns.update(self.extra_namespaces)
            for para in document.iterfind('//w:p', namespaces=ns):
                texts = [node.text
                         for node in para.iterfind('.//w:t', namespaces=ns)
                         if node.text]
                texts = map(strip, texts)
                graphics = para.iterfind('.//w:drawing', namespaces=ns)
                paragraph = Paragraph(graphics=[])
                paragraph.text = ' '.join(texts)
                for graphic in graphics:
                    name = graphic.xpath('.//pic:cNvPr/@name',
                                         namespaces=ns)
                    rel_id = graphic.xpath('.//a:blip/@r:embed',
                                           namespaces=ns)
                    # Do this check because we're indexing
                    if name and rel_id:
                        media = self.relationships[rel_id[0]]
                        media.update({'name': name[0]})
                        paragraph.graphics.append(media)
                # Do not yield textless or graphicless paragraphs
                if paragraph.text or paragraph.graphics:
                    yield paragraph

    @property
    def graphics(self):
        """Returns a generator of all graphics in the document"""
        for paragraph in self.paragraphs:
            for graphic in paragraph.graphics:
                yield graphic

    @property
    def text(self):
        """Returns a generator of all text in the document"""
        for paragraph in self.paragraphs:
            if paragraph.text:
                yield paragraph.text
