import serial

PORT = '/dev/ttyACM0'
BAUD = 9600
TIMEOUT = None


EMULATOR_MODE = False
soc_serial = None
try:
    soc_serial = serial.Serial(PORT, BAUD, timeout=TIMEOUT)
except:
    print('Could not connect to \"{!s}\". running in emulator mode'.format(PORT))
    EMULATOR_MODE = True
