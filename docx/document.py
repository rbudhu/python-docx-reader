import os
from string import strip
from zipfile import ZipFile
from lxml import etree


class Paragraph(object):
    """Stores the text and any graphics of a paragraph
    Graphics is a list of dict where the elements of the dict are the
    name of the graphic and its location in the media folder of the
    unzipped document"""
    def __init__(self, text=None, graphics=[], equations=[]):
        self.text = text
        self.graphics = graphics
        self.equations = equations


class Document(object):
    """Main representation of the document"""
    def __init__(self, path, graphics=True, equations=False):
        self.parse_graphics = graphics
        self.parse_equations = equations

        # Extra namespaces that are not included in lxml's nsmap
        self.namespaces = {
            'pic':
                'http://schemas.openxmlformats.org/drawingml/2006/picture',
            'a':
                'http://schemas.openxmlformats.org/drawingml/2006/main',
            }
        self.zip_document = ZipFile(path, 'r')
        if self.parse_equations:
            # Get the omml -> mml -> tex stylesheets
            xsl_dir = os.path.join(os.path.dirname(__file__))
            omm = os.path.join(xsl_dir, 'xsl', 'omml2mml.xsl')
            mml = os.path.join(xsl_dir, 'xsl', 'mmltex.xsl')
            self.mml_transform = etree.XSLT(etree.parse(omm))
            self.tex_transform = etree.XSLT(etree.parse(mml))
        if self.parse_graphics:
            self.relationships = self.extract_relationships()

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
            self.namespaces.update(ns)
            for para in document.iterfind('//w:p', namespaces=ns):
                texts = [node.text
                         for node in para.iterfind('.//w:t',
                                                   namespaces=self.namespaces)
                         if node.text]
                texts = map(strip, texts)
                paragraph = Paragraph(graphics=[], equations=[])
                paragraph.text = ' '.join(texts)
                if self.parse_graphics:
                    paragraph.graphics = self.extract_graphics(para)
                if self.parse_equations:
                    paragraph.equations = self.extract_equations(para)
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
    def equations(self):
        """Returns of a generator of all equations in the document"""
        for paragraph in self.paragraphs:
            for equation in paragraph.equations:
                yield equation

    @property
    def text(self):
        """Returns a generator of all text in the document"""
        for paragraph in self.paragraphs:
            if paragraph.text:
                yield paragraph.text

    def extract_graphics(self, para):
        """Extracts embedded graphics from a paragraph element"""
        extracted = []
        graphics = para.iterfind('.//w:drawing', namespaces=self.namespaces)
        for graphic in graphics:
            name = graphic.xpath('.//pic:cNvPr/@name',
                                 namespaces=self.namespaces)
            rel_id = graphic.xpath('.//a:blip/@r:embed',
                                   namespaces=self.namespaces)
            # Do this check because we're indexing
            if name and rel_id:
                media = self.relationships[rel_id[0]]
                media.update({'name': name[0]})
                extracted.append(media)
        return extracted

    def extract_equations(self, para):
        """Extracts inline equations from a paragraph element.
        Currently only handles equations that are embedded within a
        paragraph.  Does not support oMathPara (equations that are
        paragraphs by themselves)
        """
        extracted = []
        equations = para.iterfind('.//m:oMath',
                                  namespaces=self.namespaces)
        for equation in equations:
            mml = self.mml_transform(equation)
            tex = self.tex_transform(mml)
            extracted.append(str(tex))
        return extracted
