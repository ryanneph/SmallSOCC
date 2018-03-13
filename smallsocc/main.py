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

import soclog
from version import VERSION_FULL
from hardware import HWSOC
import leaflet
import leafletassembly
import sequence
import pathhandler

logger = logging.getLogger(__name__)

# define paths
PARENT = os.path.abspath(dirname(dirname(__file__)))
TEST_FILES = os.path.join(PARENT, os.path.pardir, 'test_files')
TEMP = os.path.join(PARENT, 'temp')

# TODO: Add proper python logger and integrate with Qt Message Handler
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
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Frontend for interfacing with SOC hardware',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-L', '--loglevel', type=str, choices=[*logging._nameToLevel.keys()], default=None, help='set the loglevel')
    parser.add_argument('--logconf', type=str, default='logging.conf.json', help='path to log configuration')
    args = parser.parse_args()

    # initialize logger
    soclog.init_logging(level=logging._nameToLevel.get(args.loglevel, None), config_path=args.logconf)

    # TODO: DEBUG
    # load example sequence, for rapid debugging
    try:
        samplelistmodel = sequence.SequenceListModel.fromJson(os.path.join(TEST_FILES, 'test_output.json'))
    except Exception as e:
        logger.warning('FAILED TO READ DEBUG JSON FILE : {!s}'.format(e))
        # SAMPLE ITEMS FOR DEBUG
        from sequence import SequenceItem, SequenceItemType
        sample_sequenceitems = [
            SequenceItem(rot_couch_deg=5, rot_gantry_deg=0, timecode_ms=0, datecreatedstr="2016 Oct 31 12:00:00", type='Manual'),
            SequenceItem(rot_couch_deg=12, rot_gantry_deg=120, timecode_ms=1500, description="descriptive text2", type=SequenceItemType.Auto),
            SequenceItem(rot_couch_deg=24, rot_gantry_deg=25, timecode_ms=3000, description="descriptive text3"),
            SequenceItem(rot_couch_deg=0, rot_gantry_deg=45, timecode_ms=4500, description="descriptive text4"),
        ]
        samplelistmodel = sequence.SequenceListModel(elements=sample_sequenceitems)
    # TODO: END DEBUG

    HWSOC(8, HID=None) # init singleton instance for controlling hardware

    # integrate qml logging with python logging
    QtCore.qInstallMessageHandler(qt_message_handler)
    # prevent qml caching
    os.environ['QML_DISABLE_DISK_CACHE'] = '1'

    # set QML visual style
    app = QGuiApplication(sys.argv + ['-style', 'default'])
    # register pre-exit hook
    app.aboutToQuit.connect(preExit) # perform cleanup

    ### the order here matters greatly - must init context properties before loading main.qml
    engine = QQmlApplicationEngine()
    rootContext = engine.rootContext()

    ## Set accessible properties/objects in QML Root Context
    rootContext.setContextProperty("mainwindow_title", 'SOC Controller - v{!s}(alpha)'.format(VERSION_FULL))
    # make seq. list model accessible to qml-listview
    rootContext.setContextProperty("SequenceListModel", samplelistmodel)
    pathhandler_instance = pathhandler.PathHandler()
    rootContext.setContextProperty("PathHandler", pathhandler_instance)

    # load layout
    engine.load(QtCore.QUrl(os.path.join(dirname(__file__), 'main.qml')))
    rootObject = engine.rootObjects()[0]

    ## connect signals to slots - unnecessary, example of grabbing qml objects from py-code
    # listview buttons
    #  btns = rootObject.findChildren(QQuickItem, "list_buttons", QtCore.Qt.FindChildrenRecursively)[0]
    #  btns.findChild(QQuickItem, 'btn_moveup').clicked.connect(lambda: print('moveup clicked'))

    # block until window is closed - event handler
    sys.exit(app.exec_())
