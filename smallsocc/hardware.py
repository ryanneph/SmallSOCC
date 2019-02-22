import os
import logging
import time
import binascii
import serial
from serial.threaded import Protocol
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QThread

from serialthread import SerialThread
from borg import Borg

logger = logging.getLogger(__name__)

class TSerialProtocol(Protocol, QObject):
    sigRecvdHWError   = pyqtSignal()
    sigRecvdMoveOK    = pyqtSignal()

    def __init__(self):
        Protocol.__init__(self)
        QObject.__init__(self, None)
        self._buf = b''

    def split_bytes(self, data):
        """split at '\n' or b'\x00' and return list of bytes with identifier as string or bytes"""
        tokens = []
        idx_null = data.find(b'\x00')
        idx_nl = data.find(b'\n')
        if idx_null>=0 and (idx_nl<0 or idx_null<idx_nl):
            sep = b'\x00'
        elif idx_nl>=0:
            sep = b'\n'
        else:
            return tokens

        part = data.partition(sep)
        tokens.append((part[1], part[0]))
        if len(part[2]):
            tokens += self.split_bytes(part[2])

        return tokens

    def data_received(self, data):
        try:
            # only process freshest signal if more are buffered
            if not (b'\x00' in data or '\n'.encode() in data):
                self._buf += data
                return

            data = self._buf + data
            self._buf = b''

            logger.debug2('rawdata: {!s}'.format(data))
            tokens = self.split_bytes(data)
            logger.debug2('tokens: {!s}'.format(tokens))

            for sep, bt in tokens:
                if sep == b'\x00':
                    if bytes([bt[0]]) == HWSOC.SIG_MOVE_OK:
                        logger.monitor("Recv: SIGNAL:MOVE_OK")
                        self.sigRecvdMoveOK.emit()
                    elif bytes([bt[0]]) == HWSOC.SIG_HWERROR:
                        logger.monitor("Recv: SIGNAL:HWERROR")
                        self.sigRecvdHWError.emit()
                    else:
                        logger.monitor("Recv (bin): {}".format(binascii.hexlify(bt)))

                elif sep == b'\n':
                        try:
                            str_rep = bt.decode('ascii').rstrip('\r\n')
                            logger.monitor("Recv (text): \"{}\"".format(str_rep))
                        except Exception as e:
                            logger.monitor("Recv (bin): {}".format(binascii.hexlify(bt)))
        except Exception as e:
            logger.exception("Exception encountered in signal monitor: {!s}".format(e))

    def connection_lost(self, error):
        logger.exception('Serial connection to hardware was broken')
        self.sigRecvdHWError.emit()


class HWSOC(Borg, QObject):
    """ Singleton/Borg class that handles interfacing with hardware leaflet controller """
    MAGIC_BYTES    = b'\xFF\xD7' # use before every signal sent to HW
    PRE_ABSPOS_ONE = b'\xB1'     # use before updating a single leaflet position
    PRE_ABSPOS_ALL = b'\xB2'     # use before updating all leaflet positions
    PRE_CALIBRATE  = b'\xB3'     # send without payload to reset HW encoder position state
    SIG_MOVE_OK    = b'\xA0'     # receive from HW after successful leaflet repositioning
    SIG_HWERROR    = b'\xA1'     # receive from HW after error occurs (at any time)

    def __init__(self, nleaflets=None, HID=None, BAUD=None):
        """
        Args:
            HID (str):  USB hardware id, if present: only match exactly and fallback to EMULATOR_MODE otherwise
            BAUD (int): Serial baud rate - must match serial device baud exactly
        """
        Borg.__init__(self)
        QObject.__init__(self)
        if self.__dict__.get('initialized', False):
            return

        self._tserial = None
        self.nleaflets = nleaflets
        self.init_serial_interface(HID, BAUD)
        self.initialized = True

    @pyqtProperty(QThread, constant=True)
    def tserialinterface(self):
        return self._tserial

######################################
    def send_structured_signal(self, pre_bytes, payload):
        full_payload = self.MAGIC_BYTES + pre_bytes + payload
        if self._tserial:
            self._tserial.write(full_payload)
        else:
            self._fserial.write(full_payload)
            self._fserial.reset_input_buffer()

    def is_valid_idx(self, idx):
        return idx<self.nleaflets and idx>=0

    def init_serial_interface(self, HID=None, BAUD=None):
        self._tserial = SerialThread(TSerialProtocol, HID, BAUD)
        # set to all open leaflets
        self.set_all_positions([0]*self.nleaflets)

    def close_serial_interface(self):
        self._tserial.close()
        self._tserial.join()
        self._tserial = None
######################################
    def set_position(self, idx, pos):
        """send extension for a single leaflet"""
        if not self.is_valid_idx(idx):
            raise IndexError('index specified is out of bounds')
        self.send_structured_signal(self.PRE_ABSPOS_ONE, bytes([idx]) + pos.to_bytes(2, byteorder='big', signed=True))

    def set_all_positions(self, poslist):
        """send all leaflet extensions in one bytestring"""
        if not poslist or len(poslist) != self.nleaflets:
            raise AttributeError('list of leaflet extensions must be len={} not len={}'.format(self.nleaflets, len(poslist)))
        self.send_structured_signal(self.PRE_ABSPOS_ALL, b''.join([pos.to_bytes(2, byteorder='big', signed=True) for pos in poslist]))

    def set_calibration(self):
        self.send_structured_signal(self.PRE_CALIBRATE, b'')
######################################
