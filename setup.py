#!/usr/bin/env python

from os.path import join as pjoin
from setuptools import setup, find_packages
from glob import glob
from smallsocc.version import VERSION_FULL

package_name = 'smallsocc'

setup(name='SmallSOCC',
      version=VERSION_FULL,
      description='GUI for controlling Sparse Orthogonal Collimator through serial interface',
      author='Ryan Neph',
      author_email='neph320@gmail.com',
      url='https://github.com/ryanneph/soc_control',
      packages=[package_name,],
      entry_points={
          'gui_scripts': ['{0} = {0}.gui:start_gui'.format(package_name)],
      },
      package_data={
          package_name: [
              'logging.conf.json',
              '*.qml',
              '*.js'
          ],
      },
      install_requires=[
          'PyOpenGL>=3.1.0',
          'PyQt5 >=5.9, <=5.10.1',
          'pyserial>=3.4'
      ],
)
