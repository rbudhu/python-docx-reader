#!/usr/bin/env python

from distutils.core import setup

setup(name='python-docx-reader',
      version='0.1',
      description='A .docx format reader for Python',
      author='Ravi Budhu',
      packages=['docx'],
      package_data={'docx': ['xsl/*.xsl']},
      )
