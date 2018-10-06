""" leafletassembly.py

Collection of controllable leaflets in custom configurations
"""
import logging
from hardware import HWSOC
from leaflet import Leaflet
from PyQt5.QtCore import pyqtProperty, pyqtSignal, pyqtSlot, Q_ENUMS, Q_CLASSINFO
from PyQt5.QtCore import QObject
from PyQt5.QtQml import qmlRegisterType, QQmlListProperty
from PyQt5.QtQuick import QQuickItem

logger = logging.getLogger(__name__)

class LeafletAssembly(QQuickItem):
    """Base class for all leaflet assembly types"""
    #  Q_CLASSINFO('DefaultProperty', 'leaflets')
    def __init__(self, parent=None):
        QQuickItem.__init__(self, parent)
        self._leaflets = []
        self._hwsoc = HWSOC()
        self.hw_linked = False

    def componentComplete(self):
        QQuickItem.componentComplete(self)
        self.enableHWLink()

    leafletsChanged = pyqtSignal([QQmlListProperty], arguments=['leaflets'])

    @pyqtProperty(QQmlListProperty, notify=leafletsChanged)
    def leaflets(self):
        return QQmlListProperty(Leaflet, self, self._leaflets)

    def publishToHW(self, index=None):
        poslist = [lf.extension for lf in self._leaflets]
        logger.debug('publishing all to HW - [{}]'.format(', '.join(str(x) for x in poslist)))
        self._hwsoc.set_all_positions(poslist)

    @pyqtSlot()
    def enableHWLink(self):
        if not self.hw_linked:
            self.onLeafletReleased.connect(self.publishToHW)
            self.hw_linked = True

    @pyqtSlot()
    def disableHWLink(self):
        if self.hw_linked:
            self.onLeafletReleased.disconnect(self.publishToHW)
            self.hw_linked = False

# make accessible to qml
qmlRegisterType(LeafletAssembly, 'com.soc.types.LeafletAssemblies', 1, 0, 'LeafletAssembly')
