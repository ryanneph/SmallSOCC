from hardware import HWSOC
from PyQt5.QtCore import pyqtProperty, pyqtSignal, pyqtSlot, Q_ENUMS, QObject
from PyQt5.QtQml import qmlRegisterType, qmlAttachedPropertiesObject
from PyQt5.QtQuick import QQuickItem

class LeafletAssemblyAttached(QObject):
    """ provides attached properties to Leaflet objects in context of LeafletAssembly """
    next_available = 0
    def __init__(self, parent=None):
        QObject.__init__(self, parent)
        self._index = LeafletAssemblyAttached.next_available
        LeafletAssemblyAttached.next_available += 1
        print(f'instantiating leaflet #{self._index} and attaching index property')

    @pyqtProperty(int, constant=True)
    def index(self):
        return self._index


# leaflet type to be registered with QML (must be sub-class of QObject)
class Leaflet(QQuickItem):
    _min_ext = 0
    _max_ext = 255
    next_available = 0

    # QML accessible enum defs
    class Orientation:
        Horizontal, Vertical = range(2)
    Q_ENUMS(Orientation)

    class Direction:
        Positive, Negative = range(2)
    Q_ENUMS(Direction)

    onExtensionChanged = pyqtSignal([int], arguments=['extension'])
    onIndexChanged     = pyqtSignal([int], arguments=['index'])

    def __init__(self, *args, **kwargs):
        QQuickItem.__init__(self, **kwargs)
        self._hwsoc = HWSOC()
        self._extension = 0
        self._index = Leaflet.next_available
        Leaflet.next_available += 1

    def componentComplete(self):
        QQuickItem.componentComplete(self)
        self.enableHWLink()

    @pyqtProperty(int, notify=onIndexChanged)
    def index(self):
        return self._index

    @index.setter
    def index(self, val):
        self._index = val
        self.onIndexChanged.emit(val)

    @pyqtProperty(int, constant=True)
    def min_extension(self):
        return Leaflet._min_ext

    @pyqtProperty(int, constant=True)
    def max_extension(self):
        return Leaflet._max_ext

    @pyqtProperty(int, notify=onExtensionChanged)
    def extension(self):
        return self._extension

    @extension.setter
    def extension(self, val):
        # bounds checking
        if (val < Leaflet._min_ext): val = Leaflet._min_ext
        elif (val > Leaflet._max_ext): val = Leaflet._max_ext
        self._extension = val
        self.onExtensionChanged.emit(val)

    def publishToHW(self, val):
        print('publishing to HW - leaflet #{:d} ext: {:d}'.format(self.index, val))
        self._hwsoc.set_position(self.index, self.extension)

    @pyqtSlot()
    def enableHWLink(self):
        self.onExtensionChanged.connect(self.publishToHW)

    @pyqtSlot()
    def disableHWLink(self):
        self.onExtensionChanged.disconnect(self.publishToHW)

# make Leaflet accessible to qml
qmlRegisterType(Leaflet, 'com.soc.types.Leaflets', 1, 0, 'Leaflet')
