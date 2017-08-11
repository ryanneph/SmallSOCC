import serial

PORT = '/dev/ttyACM0'
BAUD = 115200

EMULATOR_MODE = False
soc_serial = None
try:
    soc_serial = serial.Serial(PORT, BAUD, timeout=0, writeTimeout=0)
except:
    print('Could not connect to \"{!s}\". running in emulator mode'.format(PORT))
    EMULATOR_MODE = True
    raise
