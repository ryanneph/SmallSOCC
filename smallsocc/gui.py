#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""main.py

control frontend for Sparse Orthogonal Collimator (SOC)
"""
import sys
import os
from os.path import dirname
import signal
signal.signal(signal.SIGINT, signal.SIG_DFL) # allow ctrl-c kill
import argparse
import logging

from OpenGL import GL
from PyQt5 import QtCore
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtQuick import QQuickItem

FILE_DIR = os.path.abspath(os.path.dirname(__file__))
sys.path.insert(0, FILE_DIR)

import soclog
from version import VERSION_FULL
from hardware import HWSOC
import leaflet
import leafletassembly
import sequence
import pathhandler

logger = logging.getLogger(__name__)

# define paths
LIB_DIR = os.path.abspath(dirname(__file__))
INSTALL_DIR = os.path.abspath(dirname(dirname(__file__)))
TEST_FILES = os.path.join(INSTALL_DIR, os.path.pardir, 'test_files')
TEMP = os.path.join(INSTALL_DIR, 'temp')

def qt_message_handler(mode, context, message):
    if mode == QtCore.QtInfoMsg:
        # console.info()
        mode = 'INFO'
        loglevel = logging.INFO
    elif mode == QtCore.QtWarningMsg:
        # console.warn();
        mode = 'WARNING'
        loglevel = logging.WARNING
    elif mode == QtCore.QtCriticalMsg:
        # console.error()
        mode = 'ERROR'
        loglevel = logging.ERROR
    elif mode == QtCore.QtFatalMsg:
        mode = 'ERROR'
        loglevel = logging.ERROR
    else:
        # console.debug()
        if message[:2] == "2:":
            mode = 'DEBUG2'
            loglevel = logging.DEBUG2
        else:
            mode = 'DEBUG'
            loglevel = logging.DEBUG

    try:    base = os.path.basename(context.file)
    except: base = str(context.file)
    logger = logging.getLogger('qml')
    logger.log(loglevel, '%s:L%s -%s:  %s', base, context.line, mode, message)

def preExit():
    """ occurs just before Qt application exits (bound to QGuiApplication.aboutToQuit() signal) """
    #  samplelistmodel.writeToJson(os.path.join(TEMP, 'test_write.json'))
    pass


####################################################################################################
# Start GUI
def start_gui():
    parser = argparse.ArgumentParser(description='SmallSOCC v{!s} - Frontend for interfacing with SOC hardware'.format(VERSION_FULL),
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-L', '--loglevel', type=str, choices=[*logging._nameToLevel.keys()], default='WARNING', help='set the loglevel')
    parser.add_argument('--logconf', type=str, default=os.path.join(LIB_DIR, 'logging.conf.json'), help='path to log configuration')
    args = parser.parse_args()

    # initialize logger
    soclog.init_logging(level=logging._nameToLevel.get(args.loglevel, None), config_path=args.logconf)

    HWSOC(8, HID=None) # init singleton instance for controlling hardware

    listmodel = sequence.SequenceListModel()
    if args.loglevel is not 'NOTSET' and logging._nameToLevel[args.loglevel] <= logging.DEBUG:
        # load example sequence, for rapid debugging
        try:
            listmodel = sequence.SequenceListModel.fromJson(os.path.join(TEST_FILES, 'test_output.json'))
        except Exception as e:
            logger.warning('FAILED TO READ DEBUG JSON FILE : {!s}'.format(e))
            # SAMPLE ITEMS FOR DEBUG
            from sequence import SequenceItem, SequenceItemType
            sample_sequenceitems = [
                SequenceItem(rot_couch_deg=5, rot_gantry_deg=0, timecode_ms=1000, datecreatedstr="2016 Oct 31 12:00:00", type='Manual'),
                SequenceItem(rot_couch_deg=12, rot_gantry_deg=120, timecode_ms=1500, description="descriptive text2", type=SequenceItemType.Auto),
                SequenceItem(rot_couch_deg=24, rot_gantry_deg=25, timecode_ms=3000, description="descriptive text3"),
                SequenceItem(rot_couch_deg=0, rot_gantry_deg=45, timecode_ms=4500, description="descriptive text4"),
            ]
            listmodel = sequence.SequenceListModel(elements=sample_sequenceitems)



    # integrate qml logging with python logging
    QtCore.qInstallMessageHandler(qt_message_handler)
    # prevent qml caching
    os.environ['QML_DISABLE_DISK_CACHE'] = '1'

    # set QML visual style
    app = QGuiApplication(sys.argv + ['-style', 'default'])
    #  app.setAttribute(QtCore.Qt.AA_EnableHighDpiScaling, True)
    # register pre-exit hook
    app.aboutToQuit.connect(preExit) # perform cleanup

    ### the order here matters greatly - must init context properties before loading main.qml
    engine = QQmlApplicationEngine()
    rootContext = engine.rootContext()

    ## compute scaling ratios to make views dpi-independent
    if logger.getEffectiveLevel() <= logging.DEBUG:
        screens = app.screens()
        for sidx, screen in enumerate(screens):
            geometry = screen.geometry()
            dpi = screen.logicalDotsPerInch()
            logger.debug('Screen #{} ({}) - size: (w:{}, h:{}); DPI: {}'.format(sidx,  screen.name(), geometry.width(), geometry.height(), dpi))
    screen = app.primaryScreen()
    geometry = screen.geometry()
    dpi = screen.logicalDotsPerInch()

    refDpi    = 96
    refHeight = 1440
    refWidth  = 2560
    _h = min(geometry.width(), geometry.height())
    _w = max(geometry.width(), geometry.height())
    sratio = min(_h/refHeight, _w/refWidth) # element size scaling
    fratio = min(_h*refDpi/(dpi*refHeight), _w*refDpi/(dpi*refWidth)) # font pointSize scaling
    logger.debug('Setting scaling ratios - general: {}; font: {}'.format(sratio, fratio))

    ## Set accessible properties/objects in QML Root Context
    rootContext.setContextProperty("mainwindow_title", 'SOC Controller - {!s}'.format(VERSION_FULL))
    # make seq. list model accessible to qml-listview
    rootContext.setContextProperty("SequenceListModel", listmodel)
    pathhandler_instance = pathhandler.PathHandler()
    rootContext.setContextProperty("PathHandler", pathhandler_instance)
    rootContext.setContextProperty("sratio", sratio)
    rootContext.setContextProperty("fratio", fratio)
    rootContext.setContextProperty("debug_mode", logging._nameToLevel[args.loglevel]<=logging.DEBUG)

    # load layout
    engine.load(os.path.join(dirname(__file__), 'main.qml'))


    ## connect signals to slots - unnecessary, example of grabbing qml objects from py-code
    # listview buttons
    #  rootObject = engine.rootObjects()[0]
    #  btns = rootObject.findChildren(QQuickItem, "list_buttons", QtCore.Qt.FindChildrenRecursively)[0]
    #  btns.findChild(QQuickItem, 'btn_moveup').clicked.connect(lambda: print('moveup clicked'))

    # run event loop
    return app.exec_()

if __name__ == '__main__':
    # block until window is closed - event handler loop
    sys.exit(start_gui())
