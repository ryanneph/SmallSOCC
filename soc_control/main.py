#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
main.py

control frontend for Sparse Orthogonal Collimator (SOC)
"""

import sys
import os
from os.path import dirname

# We use QWidget to represent the window, QApplication as the non-vis container for the window
from OpenGL import GL
from PyQt5 import QtCore
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtQuick import QQuickItem

from version import VERSION_FULL

# allow ctrl-c kill
import signal
signal.signal(signal.SIGINT, signal.SIG_DFL)

from hardware import HWSOC
import leaflet
import leafletassembly
import sequence

parent = os.path.abspath(dirname(dirname(__file__)))
TEST_FILES = os.path.join(parent, 'test_files')
TEMP = os.path.join(parent, 'temp')

samplelistmodel = sequence.SequenceListModel.readFromJson(os.path.join(TEST_FILES, 'test_output.json'))
def preExit():
    """ occurs just before Qt application exits (bound to QGuiApplication.aboutToQuit() signal) """
    samplelistmodel.writeToJson(os.path.join(TEMP, 'test_write.json'))

####################################################################################################
# Start GUI
if __name__ == '__main__':
    HWSOC(8) # init singleton instance for controlling hardware

    app = QGuiApplication(sys.argv + ['-style', 'default'])
    app.aboutToQuit.connect(preExit) # perform cleanup

    ### the order here matters greatly - must init context properties before loading main.qml
    engine = QQmlApplicationEngine()
    rootContext = engine.rootContext()

    ## Set accessible properties/objects in QML Root Context
    rootContext.setContextProperty("mainwindow_title", 'SOC Controller - v{!s}(alpha)'.format(VERSION_FULL))
    # make seq. list model accessible to qml-listview
    rootContext.setContextProperty("SequenceListModel", samplelistmodel)

    # load layout
    engine.load(QtCore.QUrl(os.path.join(dirname(__file__), 'main.qml')))
    rootObject = engine.rootObjects()[0]

    ## connect signals to slots
    # listview buttons
    #  btns = rootObject.findChildren(QQuickItem, "list_buttons", QtCore.Qt.FindChildrenRecursively)[0]
    #  btns.findChild(QQuickItem, 'btn_moveup').clicked.connect(lambda: print('moveup clicked'))


    # block until window is closed - event handler
    sys.exit(app.exec_())
