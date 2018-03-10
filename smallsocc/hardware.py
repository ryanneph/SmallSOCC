import os
import logging
from borg import Borg
import serial
from serial.tools import list_ports

logger = logging.getLogger(__name__)

class HWSOC(Borg):
    """ Singleton/Borg class that handles interfacing with hardware leaflet controller """
    _shared_state = {}
    MAGIC_BYTES = bytes([ 0xFF, 0xD7 ])

    def __init__(self, nleaflets=None, HID=None, BAUD=115200):
        """
        Args:
            HID (str):  USB hardware id, if present: only match exactly and fallback to EMULATOR_MODE otherwise
            BAUD (int): Serial baud rate - must match serial device baud exactly
        """
        Borg.__init__(self)
        if '_fserial' in self.__dict__:
            return

        self._fserial = None
        self.EMULATOR_MODE = False
        self._USB_HID=HID
        self._BAUD = BAUD
        self._nleaflets = nleaflets
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
        if self.EMULATOR_MODE or self._fserial:
            # no need to reinit
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
        return

    @property
    def nleaflets(self):
        return self._nleaflets

    @nleaflets.setter
    def nleaflets(self, val):
        self._nleaflets = val

    def set_position(self, idx, pos):
        """send extension for a single leaflet"""
        if self.EMULATOR_MODE:
            return
        if idx >= self.nleaflets or idx < 0:
            raise IndexError('index specified is out of bounds')
        self._fserial.write(self.MAGIC_BYTES + bytes([idx]) + pos.to_bytes(2, byteorder='big', signed=False) )
        self._fserial.reset_input_buffer()

    def set_all_positions(self, poslist):
        """send all leaflet extensions in one bytestring"""
        if self.EMULATOR_MODE:
            return
        if len(poslist) > self.nleaflets or not poslist:
            raise AttributeError('list of leaflet extensions must be len={} not len={}'.format(self.nleaflets, len(poslist)))
        self._fserial.write(self.MAGIC_BYTES + b''.join([pos.to_bytes(2, byteorder='big', signed=False) for pos in poslist]))

    def go_home(self):
        """set to all open leaflets"""
        self.set_all_positions([0]*self.nleaflets)

    def get_position(self, idx):
        raise NotImplementedError('Feedback mechanism not yet implemented in hardware')

    def sync(self):
        raise NotImplementedError('HW/SW Sync not yet implemented')
