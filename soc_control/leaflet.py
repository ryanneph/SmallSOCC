from hardware import HWSOC
from PyQt5.QtCore import pyqtProperty, pyqtSignal, pyqtSlot, Q_ENUMS
from PyQt5.QtQml import qmlRegisterType
from PyQt5.QtQuick import QQuickItem

# leaflet type to be registered with QML (must be sub-class of QObject)
class LeafletBase(QQuickItem):
    __min_ext = 0
    __max_ext = 255

    class Orientation:
        Horizontal, Vertical = range(2)

    class Direction:
        Positive, Negative = range(2)

    # publish enums
    Q_ENUMS(Orientation)
    Q_ENUMS(Direction)

    #  orientationChanged = pyqtSignal(Orientation, arguments=['orientation'])
    #  directionChanged = pyqtSignal(Direction, arguments=['direction'])
    extensionChanged = pyqtSignal([int], arguments=['extension'])
    #  indexChanged = pyqtSignal([int], arguments=['index'])

    def __init__(self, *args, **kwargs):
        self._hwsoc = HWSOC()
        QQuickItem.__init__(self, **kwargs)
        self._index = 0
        self._extension = 0
        self._orientation = LeafletBase.Orientation.Horizontal
        self._direction = LeafletBase.Direction.Positive
        #  self.extensionChanged.connect(self._commit_change)

    # extend QQuickItem::componentComplete()
    def componentComplete(self):
        QQuickItem.componentComplete(self)
        self.extension = 0 # reset leaflets to home position

    @pyqtProperty(Orientation) #, notify=orientationChanged)
    def orientation(self):
        return self._orientation

    @orientation.setter
    def orientation(self, val):
        self._orientation = val

    @pyqtProperty(Direction) #, notify=directionChanged)
    def direction(self):
        return self._direction

    @direction.setter
    def direction(self, val):
        self._direction = val

    @pyqtProperty(int) #, notify=indexChanged)
    def index(self):
        return self._index

    @index.setter
    def index(self, val):
        print('setting index to {:d}'.format(val))
        self._index = val

    @pyqtProperty(int, notify=extensionChanged)
    def extension(self):
        return self._extension

    @extension.setter
    def extension(self, val):
        # bounds checking
        if (val < LeafletBase.__min_ext): val = LeafletBase.__min_ext
        elif (val > LeafletBase.__max_ext): val = LeafletBase.__max_ext
        print('setting extension of leaf #{:d} to {:d}'.format(self.index, val))
        self._extension = val
        self._commit_change()

    #  @pyqtSlot(int)
    def _commit_change(self):
        self._hwsoc.set_position(self.index, self.extension)



# make LeafletBase accessible to qml
qmlRegisterType(LeafletBase, 'com.soc.types.LeafletBase', 1, 0, 'LeafletBase')
