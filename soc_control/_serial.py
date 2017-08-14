import os
import serial
from serial.tools import list_ports
match = list_ports.grep('239A:8011')  # Magic use of hardwareID for Circuit Playground dev device
try:
    PORT = next(match).device
except StopIteration:
    pass
try:
    if os.name == 'nt':
            PORT = (list_ports.comports()[-1]).device
    else:
            PORT = (list_ports.comports()[0]).device
except:
    PORT = None
    EMULATOR_MODE = True

BAUD = 115200

EMULATOR_MODE = False
soc_serial = None
try:
    soc_serial = serial.Serial(PORT, BAUD, timeout=0, writeTimeout=0)
except:
    print('Could not connect to \"{!s}\". running in emulator mode'.format(PORT))
    EMULATOR_MODE = True
