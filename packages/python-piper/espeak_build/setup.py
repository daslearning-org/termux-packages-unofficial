# setup.py
from setuptools import setup, Extension

module = Extension(
    'espeakbridge',
    sources=['espeakbridge.c'],
    libraries=['espeak-ng'],
    include_dirs=['/data/data/com.termux/files/usr/include'],
    library_dirs=['/data/data/com.termux/files/usr/lib'],
)

setup(
    name='espeakbridge',
    version='1.0',
    ext_modules=[module]
)
