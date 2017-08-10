#!/usr/bin/env python

from setuptools import setup, find_packages
from soc_control.version import VERSION_FULL

setup(name='SOC_Control',
      version=VERSION_FULL,
      description='GUI for controlling Sparse Orthogonal Collimator through serial interface',
      author='Ryan Neph',
      author_email='neph320@gmail.com',
      url='https://github.com/ryanneph/soc_control',
      packages=find_packages(),
      install_requires=[
          'PyOpenGL>=3.1.0',
          'pyqt5>=5.9',
          'pyserial>=2.7'
      ]
      )
