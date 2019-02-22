import logging
import time
import serial
from serial.tools import list_ports
from PyQt5.QtCore import QThread, QMutex, pyqtSignal, pyqtSlot, QWaitCondition

logger = logging.getLogger(__name__)

def device_info(portinfo):
    return "deviceid=\"{}:{}\" on port=\"{!s}\" :: {} {} ({})".format(
        portinfo.vid, portinfo.pid, portinfo.name, portinfo.manufacturer, portinfo.product, portinfo.description
    )


class SerialThread(QThread):
    """
    Implement a serial port read loop and dispatch to a Protocol instance (like
    the asyncio.Protocol) but do it with threads.
    Calls to close() will close the serial port but it is also possible to just
    stop() this thread and continue the serial port instance otherwise.
    This thread should run for the life of the program whether a serial connection is active or not.
    If the connection dies, this thread is in charge of re-establishing the connection without blocking
    the gui interface
    The protocol handles serial signals once the connection has been made
    """
    _wait_connection_made  = QWaitCondition()

    def __init__(self, protocol_factory, HID=None, BAUD=None):
        """ Initialize thread """
        super(SerialThread, self).__init__()
        self.daemon = True
        self.serial = None
        self.protocol_factory = protocol_factory
        self.alive = True
        self._lock = QMutex()
        self._lock_connection = QMutex()
        self.protocol = None
        self.USB_HID = HID
        self.BAUD = BAUD if BAUD else 115200
        self.EMULATOR_MODE = False
        self.initialized = False

        self.start()
        self._lock_connection.lock()
        self._wait_connection_made.wait(self._lock_connection)
        self._lock_connection.unlock()

    def _activate_emulator_mode(self):
        self.EMULATOR_MODE = True
        try: self.serial.close()
        except: pass
        self.serial = None
        logger.warning('EMULATOR MODE ACTIVATED')

    def _deactivate_emulator_mode(self):
        self.EMULATOR_MODE = False
        logger.warning('EMULATOR MODE DEACTIVATED')

    def _init_hw(self):
        """Search for available serial devices"""
        portlist = []
        # try to exactly match by HID
        if self.USB_HID:
            match = list_ports.grep(self.USB_HID)
            try: portlist.append(next(match))
            except StopIteration:
                logger.warning("no serial devices with deviceid=\"{!s}\" were found".format(self.USB_HID))

        # try to match first available serial device
        if not portlist:
            logger.info("Discovering available serial devices...")
            portlist = list_ports.comports()
            for p in list(portlist):
                # TODO: this may be an imperfect check for a valid device
                if p.vid is None:
                    portlist.remove(p)

        for p in portlist:
            PORT = p.device
            try:
                self.serial = serial.Serial(PORT, self.BAUD, timeout=0, writeTimeout=0)
                logger.info("Connected to serial device ({!s})".format(device_info(p)))
                if not hasattr(self.serial, 'cancel_read'):
                    self.serial.timeout = 1
                break
            except serial.serialutil.SerialException:
                continue

        if self.serial is None:
            if not portlist:
                logger.warning("no serial devices were discovered")
            else:
                logger.warning("failed to open connection to any of the discovered serial devices: %s", *["\n  - {}".format(device_info(p)) for p in portlist])
                    #  logger.debug(p.device, p.name, p.description, p.hwid, p.vid, p.pid, p.serial_number, p.location, p.manufacturer, p.product, p.interface)
            if not self.initialized:
                self._activate_emulator_mode()


    def _ensure_serial_connection(self):
        logger.warning("Attempting to connect to hardware...")
        while not self.serial or not (self.serial.writable() and self.serial.readable()) :
            self._init_hw()
            if self.serial:
                logger.warning("Hardware connection successful")
                self._wait_connection_made.wakeAll()
                break
            time.sleep(1)

    def stop(self):
        """Stop the reader thread"""
        self.alive = False
        if self.serial and hasattr(self.serial, 'cancel_read'):
            try:
                self.serial.cancel_read()
            except Exception as e:
                logger.exception("Error while stopping the serial thread")

    def run(self):
        """threaded serial loop"""
        self.protocol = self.protocol_factory()
        self._init_hw()
        self.initialized = True
        self._wait_connection_made.wakeAll()

        while self.alive: # lifetime of thread
            if self.EMULATOR_MODE:
                continue

            # Check if serial connection is active and restart if not (blocking)
            self._ensure_serial_connection()

            # Read Loop
            while self.alive and self.serial and self.serial.readable():
                self._lock.lock()
                try:
                    # read all that is there or wait for one byte (blocking)
                    data = self.serial.read(self.serial.in_waiting or 1)
                    if data:
                        # make a separated try-except for called user code
                        try:
                            self.protocol.data_received(data)
                        except Exception as err:
                            logger.exception("Error in Protocol.data_received()")
                except Exception as err:
                    # probably some I/O problem such as disconnected USB serial
                    # adapters -> exit
                    self.protocol.connection_lost(err)
                    self.serial = None
                self._lock.unlock()


    def write(self, data):
        """Thread safe writing (uses lock)"""
        if self.EMULATOR_MODE:
            self.protocol.sigRecvdMoveOK.emit()
            return

        # Check if serial connection is active and error if not
        if not self.serial or not self.serial.writable():
            self.protocol.sigRecvdHWError.emit()
        else:
            self._lock.lock()
            self.serial.write(data)
            self._lock.unlock()

    def close(self):
        """Close the serial port and exit reader thread (uses lock)"""
        # use the lock to let finish writing/reading
        self._lock.lock()
        # first stop reading, so that closing can be done on idle port
        self.stop()
        try:
            self.serial.close()
        except Exception as e:
            logger.exception("Failed to close serial port")
        self._lock.unlock()
