from _serial import soc_serial, EMULATOR_MODE
from PyQt5.QtCore import QObject, pyqtProperty, Q_ENUMS
from PyQt5.QtQml import qmlRegisterType


# leaflet type to be registered with QML (must be sub-class of QObject)
class Leaflet(QObject):
    __min_ext = 0
    __max_ext = 255
    def __init__(self, idx, direction=(1,0)):
        QObject.__init__(self, parent=None)
        self._extension = 0
        self._direction = direction
        self._leafletidx = idx

    class Orientation:
        Horizontal, Vertical = range(2)

    # publish enum
    Q_ENUMS(Orientation)

    @pyqtProperty(int)
    def extension(self):
        return self._extension

    @extension.setter
    def extension(self, ext):
        # bounds checking
        if (ext < Leaflet.__min_ext): ext = Leaflet.__min_ext
        elif (ext > Leaflet.__max_ext): ext = Leaflet.__max_ext
        self._extension = ext
        self._commit_change()

    def _commit_change(self):
        if not EMULATOR_MODE:
            soc_serial.write(bytes([ 0xFF, 0xD7, self._leafletidx ]) + self._extension.to_bytes(2, byteorder='big', signed=False) )

qmlRegisterType(Leaflet, 'Leaflets', 1, 0, 'Leaflet')
