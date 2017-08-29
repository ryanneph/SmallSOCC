# Getting Started
Welcome to SOC control, a simple gui for commanding an arduino based linear stepper controller over a serial interface.
### Dependencies
Python package dependencies are handled during setup or can be installed manually using `pip install <package-name>`

- [Python >=3.4](https://www.python.org/downloads/)
- [PyQt5 5.x](https://www.riverbankcomputing.com/software/pyqt/download5)
- PyOpenGL 3.x
- PySerial 3.x

### Installation
```
git clone https://github.com/ryanneph/soc_control.git
cd soc_control && python setup.py install
```
### Development
#### Using virtualenv
```bash 
git clone https://github.com/ryanneph/soc_control.git
pip install virtualenv
virtualenv soc_dev && source soc_dev/bin/activate
cd soc_control && python setup.py develop
```
#### Using Anaconda/Conda
```bash
conda create -n soc_dev python=3
conda activate soc_dev
cd soc_control && python setup.py develop
```
If setup fails to install all dependencies, you may install them manually using:
`pip install <package-name>`


### Platform Considerations
Communicating with serial ports is a bit different on windows and linux. 
In linux, serial comm. is handled by the kernel and accessible using virtual file-like descriptors 
that typically show as `/dev/ttyACMx` or `/dev/ttyUSBx` depending on your distribution.
In windows, serial devices are assigned to a COMx ports instead. All of this should be relatively transparent since the PySerial package
provides a convenient way to list all accessible serial ports regardless of the system.
