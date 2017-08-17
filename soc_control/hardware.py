import os
from borg import Borg
import serial
from serial.tools import list_ports

_BAUD = 115200
_USB_HID = '239A:8011'  # hardwareID for detecting device

class HWSOC(Borg):
    _shared_state = {}

    def __init__(self, nleaflets=None):
        Borg.__init__(self)
        try: self._fserial
        except:
            self._fserial = None
            self.EMULATOR_MODE = False
            self._nleaflets = 0
        if nleaflets:
            self._nleaflets = nleaflets
        self._init_hw()

    def _activate_emulator_mode(self):
        self.EMULATOR_MODE = True
        try: self._fserial.close()
        except: pass
        self._fserial = None
        print('EMULATOR MODE ACTIVATED')

    def _init_hw(self):
        if self._fserial:
            # no need to reinit
            return
        match = list_ports.grep(_USB_HID)
        try:
            PORT = next(match).device
        except StopIteration:  # no HID matches
            try:
                if os.name == 'nt':
                    PORT = (list_ports.comports()[-1]).device
                else:
                    PORT = (list_ports.comports()[0]).device
            except:
                self._activate_emulator_mode()
                return
        try:
            self._fserial = serial.Serial(PORT, _BAUD, timeout=0, writeTimeout=0)
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

    def get_position(self, idx):
        """Feedback mechanism not yet implemented in hardware"""
        pass

    def go_home(self):
        for i in range(self.nleaflets):
            self.set_position(i, 0)
