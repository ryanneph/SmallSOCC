# Getting Started
Welcome to SmallSOCC, a simple gui for commanding an arduino based linear stepper hardware over a serial interface.

<p align="center">
    <img src="resources/demo.gif" style="max-height:500px" height="auto" width="auto" />
</p>

### Dependencies
Python package dependencies are handled during setup or can be installed manually using `pip install <package-name>`
(see setup.py for up-to-date dependencies)
### Installation
clone the repository:
```bash
git clone https://github.com/ryanneph/SmallSOCC.git
cd SmallSOCC
```
then install using pip:
```bash
python -m pip install .
```
finally run with: 
```bash
smallsocc
```
or run directly with:
```bash
python smallsocc/gui.py
```

### Development
When installed as a development package, changes to the source code will be immediately reflected the next
time `smallsocc` is run, without requiring a re-installation.

First clone the repository as before, then install:
```bash
python -m pip install -e .
```
It is encouraged to install into a virtualenv rather than your default python dist: 
```bash 
python -m pip install virtualenv
virtualenv soc_dev && source soc_dev/bin/activate
python -m pip install -e .
```

#### Developing for the Hardware Microcontroller
Install [PlatformIO IDE](https://docs.platformio.org/en/latest/ide/pioide.html)  
or, [PlatformIO cli](https://docs.platformio.org/en/latest/installation.html):
```bash
sudo python -m pip install -U platformio
```
Then initialize the development environment, build the code, and flash it to the device
```bash
cd soc_driver
pio init -b <board-id>
pio run --target upload
```

----------------------------
## Addendum
### Platform Considerations
Communicating with serial ports is a bit different on windows and linux. 

In linux, serial ports are accessed using virtual file-like descriptors 
that typically show as `/dev/ttyACMx` or `/dev/ttyUSBx`.

In windows, serial devices are assigned to a COMx ports instead. All of this should be relatively opaque since the PySerial package
provides a convenient way to list all accessible serial ports regardless of the system.

Every attempt has been made to automatically detect the correct serial device on startup, but if manual specification is necessary,
you may feed the your usb hardware ID as an argument to the device initialization function `HWSOC(8, HID=<xxxx:xxxx>)` in `VID:PID` format.
You can view the detected devices and their HIDs by inspecting the command line warnings after a failure to connect.
