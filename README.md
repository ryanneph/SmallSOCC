# Getting Started
Welcome to SmallSOCC, a simple gui for commanding an arduino based linear stepper hardware over a serial interface.

<p align="center">
    <img src="resources/demo.gif" style="max-height:500px" height="auto" width="auto" />
</p>

### Dependencies
Python package dependencies are handled during setup or can be installed manually using `pip install <package-name>`

- [Python >=3.4](https://www.python.org/downloads/)
- [PyQt5 5.x](https://www.riverbankcomputing.com/software/pyqt/download5)
- PyOpenGL 3.x
- PySerial 3.x

### Installation
```
git clone https://github.com/ryanneph/SmallSOCC.git
cd SmallSOCC && python setup.py install
```
### Development
#### Using virtualenv
```bash 
git clone https://github.com/ryanneph/SmallSOCC.git
pip install virtualenv
virtualenv soc_dev && source soc_dev/bin/activate
cd SmallSOCC && python setup.py develop
```
#### Using Anaconda/Conda
```bash
conda create -n soc_dev python=3
conda activate soc_dev
cd SmallSOCC && python setup.py develop
```
If setup fails to install all dependencies, you may install them manually using:
`pip install <package-name>`

----------------------------
## Addendum
### Platform Considerations
Communicating with serial ports is a bit different on windows and linux. 

In linux, serial comm. is handled by the kernel and accessible using virtual file-like descriptors 
that typically show as `/dev/ttyACMx` or `/dev/ttyUSBx` depending on your distribution.

In windows, serial devices are assigned to a COMx ports instead. All of this should be relatively invisible since the PySerial package
provides a convenient way to list all accessible serial ports regardless of the system.

Every attempt has been made to automatically detect
the correct serial device on startup, but if manual specification is necessary, you may feed the your usb hardware ID as an argument to the device initialization function `HWSOC(8, HID=<xxxx:xxxx>)` in `VID:PID` format. You can view the detected devices and their HIDs by inspecting the command line warnings after a failure to connect.
