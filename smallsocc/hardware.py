import os
import logging
from borg import Borg
import serial
from serial.tools import list_ports
from serial.threaded import Protocol, ReaderThread
import binascii

logger = logging.getLogger(__name__)

class RecvSignalHandler(Protocol):
    def __init__(self):
        super().__init__()

    def connection_made(self, transport):
        logger.debug("began threaded serial read-loop")

    def data_received(self, data):
        # only process freshest signal if more are buffered
        if bytes([data[-1]]) == HWSOC.SIG_MOVE_OK:
            logger.monitor("Recv: SIGNAL:MOVE_OK")
        elif bytes([data[-1]]) == HWSOC.SIG_HWERROR:
            logger.monitor("Recv: SIGNAL:HWERROR")
            #TODO: Signal to GUI that an error has occured
        else:
            for d in data.split('\n'.encode()):
                try:
                    str_rep = d.decode('utf-8').rstrip('\r\n')
                    logger.monitor("Recv (text): \"{}\" ({})".format(str_rep, binascii.hexlify(d)))
                except Exception as e:
                    logger.monitor("Recv (bin): {}".format(binascii.hexlify(d)))


class HWSOC(Borg):
    """ Singleton/Borg class that handles interfacing with hardware leaflet controller """
    MAGIC_BYTES    = b'\xFF\xD7' # use before every signal sent to HW
    PRE_ABSPOS_ONE = b'\xB1'     # use before updating a single leaflet position
    PRE_ABSPOS_ALL = b'\xB2'     # use before updating all leaflet positions
    PRE_CALIBRATE  = b'\xB3'     # send without payload to reset HW encoder position state
    SIG_MOVE_OK    = b'\x50'     # receive from HW after successful leaflet repositioning
    SIG_HWERROR    = b'\x51'     # receive from HW after error occurs (at any time)

    def __init__(self, nleaflets=None, HID=None, BAUD=115200):
        """
        Args:
            HID (str):  USB hardware id, if present: only match exactly and fallback to EMULATOR_MODE otherwise
            BAUD (int): Serial baud rate - must match serial device baud exactly
        """
        Borg.__init__(self)
        if self.__dict__.get('initialized', False):
            return

        self.initialized = False
        self._fserial = None
        self.recvsighandler = None
        self.EMULATOR_MODE = False
        self._USB_HID=HID
        self._BAUD = BAUD
        self.nleaflets = nleaflets

        self._init_hw()

    def _activate_emulator_mode(self):
        self.EMULATOR_MODE = True
        try: self._fserial.close()
        except: pass
        self._fserial = None
        logger.warning('EMULATOR MODE ACTIVATED')

    @staticmethod
    def device_info(portinfo):
        return "deviceid=\"{}:{}\" on port=\"{!s}\" :: {} {} ({})".format(
            portinfo.vid, portinfo.pid, portinfo.name, portinfo.manufacturer, portinfo.product, portinfo.description
        )

    def _init_hw(self):
        if self.initialized:
            return

        portlist = []
        # try to exactly match by HID
        if self._USB_HID:
            match = list_ports.grep(self._USB_HID)
            try: portlist.append(next(match))
            except StopIteration:
                logger.warning("no serial devices with deviceid=\"{!s}\" were found".format(self._USB_HID))

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
                self._fserial = serial.Serial(PORT, self._BAUD, timeout=0, writeTimeout=0)
                logger.info("Connected to serial device ({!s})".format(self.device_info(p)))
                break
            except serial.serialutil.SerialException:
                continue

        if self._fserial is None:
            if not portlist:
                logger.warning("no serial devices were discovered")
            else:
                logger.warning("failed to open connection to any of the discovered serial devices: %s", *["\n  - {}".format(self.device_info(p)) for p in portlist])
                    #  logger.debug(p.device, p.name, p.description, p.hwid, p.vid, p.pid, p.serial_number, p.location, p.manufacturer, p.product, p.interface)
            self._activate_emulator_mode()
        else:
            self.start_signal_handler()
            # set to all open leaflets
            self.set_all_positions([0]*self.nleaflets)
        self.initialized = True
        return

######################################
    def send_structured_signal(self, pre_bytes, payload):
        full_payload = self.MAGIC_BYTES + pre_bytes + payload
        if self.recvsighandler:
            self.recvsighandler.write(full_payload)
        else:
            self._fserial.write(full_payload)
            self._fserial.reset_input_buffer()

    def is_valid_idx(self, idx):
        return idx<self.nleaflets and idx>=0

    def connection_lost(self, exc):
        if exc:
            logger.debug1("lost connection to serial interface")
            raise exc

    def start_signal_handler(self):
        self.recvsighandler = ReaderThread(self._fserial, RecvSignalHandler)
        self.recvsighandler.start()

    def stop_signal_handler(self):
        self.recvsighandler.join()
        self.recvsighandler = None
######################################
    def set_position(self, idx, pos):
        """send extension for a single leaflet"""
        if self.EMULATOR_MODE:
            return
        if not self.is_valid_idx(idx):
            raise IndexError('index specified is out of bounds')
        self.send_structured_signal(self.PRE_ABSPOS_ONE, bytes([idx]) + pos.to_bytes(2, byteorder='big', signed=True))

    def set_all_positions(self, poslist):
        """send all leaflet extensions in one bytestring"""
        if self.EMULATOR_MODE:
            return
        if not poslist or len(poslist) != self.nleaflets:
            raise AttributeError('list of leaflet extensions must be len={} not len={}'.format(self.nleaflets, len(poslist)))
        self.send_structured_signal(self.PRE_ABSPOS_ALL, b''.join([pos.to_bytes(2, byteorder='big', signed=True) for pos in poslist]))

    def set_calibration(self):
        self.send_structured_signal(self.PRE_CALIBRATE, b'')
######################################

    def get_position(self, idx):
        raise NotImplementedError('Feedback mechanism not yet implemented in hardware')

    def sync(self):
        raise NotImplementedError('HW/SW Sync not yet implemented')
