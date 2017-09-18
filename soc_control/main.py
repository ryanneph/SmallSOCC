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
from PyQt5.QtCore import Qt, QUrl
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import QQmlApplicationEngine

from version import VERSION_FULL

# allow ctrl-c kill
import signal
signal.signal(signal.SIGINT, signal.SIG_DFL)

from hardware import HWSOC
import leaflet
import leafletassembly


####################################################################################################
# Start GUI
if __name__ == '__main__':
    HWSOC(8)

    app = QApplication(sys.argv)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("mainwindow_title", 'SOC Controller - v{!s}(alpha)'.format(VERSION_FULL))
    engine.load(QUrl(os.path.join(dirname(__file__), 'main.qml')))
    sys.exit(app.exec_()) # block until window is closed - event handler
