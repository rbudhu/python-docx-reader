# python-docx-reader

A simple Microsoft Word .docx reader for Python.

Parses paragraphs, graphics, and inline equations (to tex)

Installation
------------

python setup.py install

Usage
-------------
    from docx.document import Document
    doc = Document('path/to/your/docx/file')
    # or doc = Document('path/to/your/docx/file', graphics=True, equations=True)
    
    # Get generator of all paragraphs
    paragraphs = doc.paragraphs
    # Iterate over paragraphs and print paragraph text, graphics, and equations
    for paragraph in paragraphs:
        print(paragraph.text)
        print(paragraph.graphics)
        print(paragraph.equations)
    # Get all of the text, graphics, and equations in the document
    print(doc.text)
    print(doc.graphics)
    print(doc.equations)
