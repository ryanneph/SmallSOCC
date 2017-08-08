from PyQt5.QtWidgets import QWidget
from PyQt5 import QtGui
from PyQt5.QtGui import QPainter, QColor, QFont, QIcon

class SOCDisplay(QWidget):
    def __init__(self, parent, position_hv, size_wh):
        QWidget.__init__(self, parent)
        self.size_wh = size_wh
        self.position_hv = position_hv
        self.initUI()

    def initUI(self):
        # prepare display for interacting with SOC leaflets
        self.setGeometry(*self.position_hv, *self.size_wh)
        self.setAutoFillBackground(True)
        pal = self.palette()
        pal.setColor(self.backgroundRole(), QColor(242,250,255))
        self.setPalette(pal)
        self.show()

    def paintEvent(self, event):
        qp = QPainter()
        qp.begin(self)
        self.drawBoundBox(qp)
        qp.end()

    def drawBoundBox(self, qp):
        """Draws box describing deliverable field limits"""
        qp.setPen(Qt.red)
        qp.drawRect(*tuple(map(lambda x: x/4, self.size_wh)), *tuple(map(lambda x: x/2, self.size_wh)))



class Main(QWidget):
    def __init__(self):
        QWidget.__init__(self)
        self.initUI()

    def initUI(self):
        self.text = "akjdsfkjsdf"
        #  self.setGeometry(300, 300, 200, 200)
        window_size = (900, 600)
        socdisp_size = (window_size[1], window_size[1])
        socdisp_pos = (0,0)
        self.resize(*window_size)
        self.setWindowTitle('SOC Controller - v{!s}'.format(VERSION_FULL))
        self.setWindowIcon(QIcon('icon_main.png'))
        socdisp = SOCDisplay(self, socdisp_pos, socdisp_size)

        self.show()

    # override QWidget.paintEvent() - which is called on self.show()
    #  def paintEvent(self, event):
    #      qp = QPainter()
    #      qp.begin(self)
    #      # INSERT PAINT EVENTS HERE
    #      qp.end()
