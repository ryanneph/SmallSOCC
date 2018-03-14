import sched, time
from pyQt5.QtCore pyqtProperty, pyqtSignal, pyqtSlot, QObject

class TreatmentManager(QObject):
    advance = pyqtSignal()
    finished = pyqtSignal()

    def __init__(self, durations, parent=None, *args):
        super().__init__(parent=parent, *args)
        self.durs = durations

        # setup scheduler with all times
        self.sched =

    @pyqtSlot()
    def start(self):




