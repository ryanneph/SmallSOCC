import os
import sys
from PyQt5.QtCore import pyqtSlot, QObject

class PathHandler(QObject):
    def __init__(self, parent=None, **kwargs):
        super(PathHandler, self).__init__(parent, **kwargs)

    @pyqtSlot('QString', result='QString')
    def cleanpath(self, p):
        """take a QURL and clean it up as an OS-specific path"""
        if sys.platform != 'win32':
            if p[0] != '/':
                p = '/' + p
        return os.path.abspath(os.path.expanduser(p))
