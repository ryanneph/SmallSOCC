import time
import logging
from PyQt5.QtCore import QThread, QMutex, QWaitCondition, \
                         QObject, pyqtSignal, pyqtSlot, pyqtProperty, QCoreApplication
import sequence
import settings
from hardware import HWSOC

logger = logging.getLogger(__name__)

class TreatmentManagerProxy(QObject):
    """A proxy object is necessary to allow QML code to directly send signals to the TreatmentManager living on another QThread"""
    onTreatmentStarted   = pyqtSignal()
    onTreatmentStopped   = pyqtSignal(int)
    onTreatmentAborted   = pyqtSignal(int)
    onTreatmentFreeze    = pyqtSignal(int)
    onTreatmentUnfreeze  = pyqtSignal()
    onTreatmentCompleted = pyqtSignal(int)
    onTreatmentAdvance   = pyqtSignal(int)
    onTreatmentSkip      = pyqtSignal(int, float)

    # cross-thread control via signals
    startTreatment    = pyqtSignal([int])
    stopTreatment     = pyqtSignal()
    restartTreatment  = pyqtSignal()
    abortTreatment    = pyqtSignal()
    freezeTreatment   = pyqtSignal()
    unfreezeTreatment = pyqtSignal()
    setHWOK           = pyqtSignal()

    onStepsChanged = pyqtSignal([int])
    @pyqtProperty(int, notify=onStepsChanged)
    def steps(self):
        return self.tm.steps
        pass

    def __init__(self, tm, parent=None, *args):
        super().__init__(parent, *args)
        self.tm = tm
        # tie signals together to mediate connection between QML and separate threaded worker (TreatmentManager)
        self.startTreatment.connect(tm.startTreatment)
        self.stopTreatment.connect(tm.stopTreatment)
        self.restartTreatment.connect(tm.restartTreatment)
        self.abortTreatment.connect(tm.abortTreatment)
        self.freezeTreatment.connect(tm.freezeTreatment)
        self.unfreezeTreatment.connect(tm.unfreezeTreatment)
        self.setHWOK.connect(tm.setHWOK)
        tm.onTreatmentStarted.connect(self.onTreatmentStarted)
        tm.onTreatmentStopped.connect(self.onTreatmentStopped)
        tm.onTreatmentAborted.connect(self.onTreatmentAborted)
        tm.onTreatmentFreeze.connect(self.onTreatmentFreeze)
        tm.onTreatmentUnfreeze.connect(self.onTreatmentUnfreeze)
        tm.onTreatmentCompleted.connect(self.onTreatmentCompleted)
        tm.onTreatmentAdvance.connect(self.onTreatmentAdvance)
        tm.onTreatmentSkip.connect(self.onTreatmentSkip)
        tm.onStepsChanged.connect(self.onStepsChanged)

class TreatmentManager(QObject):
    def __init__(self, sequencelistmodel, parent=None, *args):
        super().__init__(parent=parent, *args)

        self.seqlist = sequencelistmodel
        self._hwsoc = HWSOC()
        self.mark = 0
        self._steps = 0
        self._sequence_cache = None

        # thread locks
        self.lock_running = QMutex()
        self.lock_waiting = QMutex()
        self.lock_waitcond = QWaitCondition()
        self.lock_steps = QMutex()

        # state variables
        self.state_paused = False
        self.state_running = False
        self.state_waitinghwok = False

        self.startTreatment.connect(self._startTreatment)
        self.stopTreatment.connect(self._stopTreatment)
        self.restartTreatment.connect(self._restartTreatment)
        self.abortTreatment.connect(self._abortTreatment)
        self.freezeTreatment.connect(self._freezeTreatment)
        self.unfreezeTreatment.connect(self._unfreezeTreatment)
        self.setHWOK.connect(self._sethwok)

        # create QThread and move this object to it
        self.thread = QThread()
        self.moveToThread(self.thread)
        self.thread.start()

    onTreatmentStarted   = pyqtSignal()
    onTreatmentStopped   = pyqtSignal(int)
    onTreatmentAborted   = pyqtSignal(int)
    onTreatmentFreeze    = pyqtSignal(int)
    onTreatmentUnfreeze  = pyqtSignal()
    onTreatmentCompleted = pyqtSignal(int)
    onTreatmentAdvance   = pyqtSignal(int)
    onTreatmentSkip      = pyqtSignal(int, float)

    # cross-thread control via signals
    startTreatment    = pyqtSignal([int])
    stopTreatment     = pyqtSignal()
    restartTreatment  = pyqtSignal()
    abortTreatment    = pyqtSignal()
    freezeTreatment   = pyqtSignal()
    unfreezeTreatment = pyqtSignal()
    setHWOK           = pyqtSignal()

    onStepsChanged = pyqtSignal([int])
    @pyqtProperty(int, notify=onStepsChanged)
    def steps(self):
        self.lock_steps.lock()
        v = self._steps
        self.lock_steps.unlock()
        return v

    @steps.setter
    def steps(self, v):
        self.lock_steps.lock()
        self._steps = v
        self.lock_steps.unlock()

    onWaitingChanged = pyqtSignal([bool])
    @pyqtProperty(bool, notify=onWaitingChanged)
    def waitinghwok(self):
        self.lock_waiting.lock()
        v = self.state_waitinghwok
        self.lock_waiting.unlock()
        return v

    @waitinghwok.setter
    def waitinghwok(self, v):
        self.lock_waiting.lock()
        self.state_waitinghwok = v
        self.lock_waiting.unlock()

    onRunningChanged = pyqtSignal([bool])
    @pyqtProperty(bool, notify=onRunningChanged)
    def running(self):
        self.lock_running.lock()
        v = self.state_running
        self.lock_running.unlock()
        return v

    @running.setter
    def running(self, v):
        self.lock_running.lock()
        self.state_running = v
        self.lock_running.unlock()

    def deliverAll(self):
        while self.mark < len(self._sequence_cache) and self.running:
            duration = self.deliverOne()

            # advance to next segment?
            if self.running:
                if self.mark < len(self.seqlist)-1:
                    self.mark += 1
                    self.steps += 1
                    #  if duration >= 1000:
                    if settings.update_sw_leaflets_during_treatment:
                        self.onTreatmentAdvance.emit(self.mark) # only updates UI
                else:
                    self._stopTreatment()
                    self.state_paused = False
                    self.onTreatmentCompleted.emit(self.mark) #update ui

    def deliverOne(self):
        """Run timer for a single beam"""
        seg = self._sequence_cache[self.mark]
        extension_list = seg._members['extension_list'].value
        duration = float(seg._members['timecode_ms'].value)
        if duration <= 0:
            self.waitinghwok = True
            self.onTreatmentSkip.emit(self.mark, duration)
        else:
            self.waitinghwok = True
            self._hwsoc.set_all_positions(extension_list)
            while self.waitinghwok:
                # spin event loop until hwok signal is recieved after delivery of prev. segment
                QCoreApplication.processEvents()

            t1 = time.perf_counter()
            while (time.perf_counter()-t1) < duration*0.001:
                # catch signals every 250ms while delivering
                if (time.perf_counter()-t1)%0.25:
                    QCoreApplication.processEvents()
                if not self.state_running:
                    # early exit from UI
                    break
        return duration

    def _sethwok(self):
        self.waitinghwok = False

    @pyqtSlot(int)
    def _startTreatment(self, index):
        """Start the treatment at specified index"""
        self.mark = index
        self._sequence_cache = self.seqlist._items.copy()
        if not self.state_paused:
            self.steps = 1
        self.running = True
        self.onTreatmentStarted.emit()
        logger.debug("Treatment started")
        self.deliverAll()

    def _stopTreatment(self):
        self.state_paused = True
        self.running = False
        self.onTreatmentStopped.emit(self.mark)
        logger.debug("Treatment stopped")

    def _freezeTreatment(self):
        """Handling for lost HW connection, can be auto-resumed with self._unfreezeTreatment"""
        if self.running:
            self.running = False
            self.state_paused = True
            self.onTreatmentFreeze.emit(self.mark)
            logger.debug("Treatment frozen")
        else:
            self.state_paused = False

    def _unfreezeTreatment(self):
        """recover from frozen treatment (due to hw disconnection)"""
        if self.state_paused:
            self.running = True
            self.onTreatmentUnfreeze.emit()
            logger.debug("Treatment unfrozen")

    def _restartTreatment(self):
        self.steps = 0
        self.state_paused = False
        self._startTreatment(0)
        logger.debug("Treatment restarted")

    def _abortTreatment(self):
        self.running = False
        self.state_paused = False
        self.onTreatmentAborted.emit(self.mark)
        logger.debug("Treatment aborted")
