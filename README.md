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
then install using pip or pipenv:
```bash
pip install .
```
or
```bash
pip install pipenv
pipenv install .
```
finally run with: 
```bash
smallsocc
```
or 
```bash
python smallsocc/gui.py
```
### Development
When installed as a development package, changes to the source code will be immediately reflected the next
time `smallsocc` is run, without requiring a re-installation.

First clone the repository:
```bash
git clone https://github.com/ryanneph/SmallSOCC.git
cd SmallSOCC
```
Then install:
#### Using pipenv (preferred way)
```bash
pip install pipenv
pipenv install -e .
```
#### Using Anaconda/Conda
```bash
conda create -n soc_dev python=3
conda activate soc_dev
python -m pip install -e .
```
#### Using virtualenv
```bash 
pip install virtualenv
virtualenv soc_dev && source soc_dev/bin/activate
python -m pip install -e .
```

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
