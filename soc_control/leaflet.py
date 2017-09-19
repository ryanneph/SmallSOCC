from hardware import HWSOC
from PyQt5.QtCore import pyqtProperty, pyqtSignal, pyqtSlot, Q_ENUMS
from PyQt5.QtQml import qmlRegisterType
from PyQt5.QtQuick import QQuickItem

# leaflet type to be registered with QML (must be sub-class of QObject)
class Leaflet(QQuickItem):
    __min_ext = 0
    __max_ext = 255

    class Orientation:
        Horizontal, Vertical = range(2)

    class Direction:
        Positive, Negative = range(2)

    # publish enums
    Q_ENUMS(Orientation)
    Q_ENUMS(Direction)

    orientationChanged = pyqtSignal(Orientation, arguments=['orientation'])
    directionChanged = pyqtSignal(Direction, arguments=['direction'])
    extensionChanged = pyqtSignal([int], arguments=['extension'])
    indexChanged = pyqtSignal([int], arguments=['index'])

    def __init__(self, *args, **kwargs):
        QQuickItem.__init__(self, **kwargs)
        self._hwsoc = HWSOC()
        self._index = 0
        self._extension = 0
        self._orientation = Leaflet.Orientation.Horizontal
        self._direction = Leaflet.Direction.Positive

    # extend QQuickItem::componentComplete()
    def componentComplete(self):
        QQuickItem.componentComplete(self)
        #  self.extension = 0 # reset leaflets to home position

    @pyqtProperty(int, constant=True)
    def min_extension(self):
        return Leaflet.__min_ext

    @pyqtProperty(int, constant=True)
    def max_extension(self):
        return Leaflet.__max_ext

    @pyqtProperty(Orientation, notify=orientationChanged)
    def orientation(self):
        return self._orientation

    @orientation.setter
    def orientation(self, val):
        self._orientation = val

    @pyqtProperty(Direction, notify=directionChanged)
    def direction(self):
        return self._direction

    @direction.setter
    def direction(self, val):
        self._direction = val

    @pyqtProperty(int, notify=indexChanged)
    def index(self):
        return self._index

    @index.setter
    def index(self, val):
        self._index = val

    @pyqtProperty(int, notify=extensionChanged)
    def extension(self):
        return self._extension

    @extension.setter
    def extension(self, val):
        # bounds checking
        if (val < Leaflet.__min_ext): val = Leaflet.__min_ext
        elif (val > Leaflet.__max_ext): val = Leaflet.__max_ext
        print('setting extension of leaflet #{:d} to {:d}'.format(self.index, val))
        self._extension = val
        self._commit_change()

    def _commit_change(self):
        self._hwsoc.set_position(self.index, self.extension)



# make Leaflet accessible to qml
qmlRegisterType(Leaflet, 'com.soc.types.Leaflets', 1, 0, 'Leaflet')
