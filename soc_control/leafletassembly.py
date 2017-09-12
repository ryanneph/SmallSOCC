"""leafletassembly.py

Collection of controllable leaflets in custom configurations
"""
from hardware import HWSOC
from PyQt5.QtCore import pyqtProperty, pyqtSignal, pyqtSlot, Q_ENUMS
from PyQt5.QtQml import qmlRegisterType
from PyQt5.QtQuick import QQuickItem

class LeafletAssemblyBase():
    """Base class for all leaflet assembly types"""
    def __init__(self):
        self.leaflets = []

    def set_positions(pos_map):
        for (idx, pos) in pos_map.items():
            HWSOC.set_position(idx, pos)

class LeafletAssembly2by2(LeafletAssemblyBase, QQuickItem):
    def __init__(self, *args, **kwargs):
        QQuickItem.__init__(self, **kwargs)
        LeafletAssemblyBase.__init__(self)


# make accessible to qml
qmlRegisterType(LeafletAssembly2by2, 'com.soc.types.LeafletAssemblyBase', 1, 0, 'LeafletAssembly2by2')

