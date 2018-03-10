import os
import sys
import logging
from PyQt5.QtCore import pyqtSlot, QObject

logger = logging.getLogger(__name__)

class PathHandler(QObject):
    def __init__(self, parent=None, **kwargs):
        super(PathHandler, self).__init__(parent, **kwargs)

    @pyqtSlot(str, result=str)
    def cleanpath(self, p):
        """take a QURL and clean it up as an OS-specific path"""
        path = p
        if sys.platform == 'win32':
            path = str.lstrip('/')
        else:
            if path[0] != '/':
                path = '/' + path
        path = os.path.abspath(os.path.expanduser(path))
        if path != p:
            logger.debug('converted path "{}" to "{}"'.format(p, path))
        return path
