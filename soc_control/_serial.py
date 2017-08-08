import serial

PORT = '/dev/ttyACM0'
BAUD = 9600
TIMEOUT = 10


EMULATOR_MODE = False
soc_serial = None
try:
    soc_serial = serial.Serial(PORT, 9600, timeout=5)
except:
    print('Could not connect to \"{!s}\". running in emulator mode'.format(PORT))
    EMULATOR_MODE = True
