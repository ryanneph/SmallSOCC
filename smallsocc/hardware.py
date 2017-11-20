import os
from borg import Borg
import serial
from serial.tools import list_ports

class HWSOC(Borg):
    """ Singleton/Borg class that handles interfacing with hardware leaflet controller """
    _shared_state = {}

    def __init__(self, nleaflets=None, HID=None, BAUD=115200):
        """
        Args:
            HID (str):  USB hardware id, if present: only match exactly and fallback to EMULATOR_MODE otherwise
            BAUD (int): Serial baud rate - must match serial device baud exactly
        """
        Borg.__init__(self)
        try: self._fserial
        except:
            self._fserial = None
            self.EMULATOR_MODE = False
            self._nleaflets = 0

        self._USB_HID=HID
        self._BAUD = BAUD
        self._nleaflets = nleaflets
        self._init_hw()

    def _activate_emulator_mode(self):
        self.EMULATOR_MODE = True
        try: self._fserial.close()
        except: pass
        self._fserial = None
        print('EMULATOR MODE ACTIVATED')

    def _init_hw(self):
        if self.EMULATOR_MODE or self._fserial:
            # no need to reinit
            return
        try:
            # try to exactly match by HID
            if self._USB_HID:
                match = list_ports.grep(self._USB_HID)
                PORT = next(match).device
            # try to match first available serial device
            else:
                if os.name == 'nt':
                    PORT = (list_ports.comports()[-1]).device
                else:
                    PORT = (list_ports.comports()[0]).device
                self._fserial = serial.Serial(PORT, self._BAUD, timeout=0, writeTimeout=0)
        except:
            self._activate_emulator_mode()
            return

    @property
    def nleaflets(self):
        return self._nleaflets

    @nleaflets.setter
    def nleaflets(self, val):
        self._nleaflets = val

    def set_position(self, idx, pos):
        if self.EMULATOR_MODE:
            return
        if idx >= self.nleaflets or idx < 0:
            raise IndexError('index specified is out of bounds')
        self._fserial.write(bytes([ 0xFF, 0xD7, idx ]) + pos.to_bytes(2, byteorder='big', signed=False) )
        self._fserial.reset_input_buffer()

    def go_home(self):
        for i in range(self.nleaflets):
            self.set_position(i, 0)

    def get_position(self, idx):
        raise NotImplementedError('Feedback mechanism not yet implemented in hardware')

    def sync(self):
        raise NotImplementedError('HW/SW Sync not yet implemented')
