import sys
import random

import PyQt5.QtWidgets as qtw
import PyQt5.QtGui as qtg
import PyQt5.QtCore as qtc


class MainWindow(qtw.QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Paint Drawing Test")
        outerLayout = qtw.QVBoxLayout()

        self.setLayout(outerLayout)

        self.draw_points = qtw.QPushButton("Toggle Points")
        self.draw_points.setCheckable(True)
        self.draw_points.toggle()
        self.draw_points.clicked.connect(self.pressed)
        outerLayout.addWidget(self.draw_points)

        self.canSeeSkeleton = False

        self.show()

    def paintEvent(self, a0: qtg.QPaintEvent):
        qp = qtg.QPainter()
        qp.begin(self)
        if self.canSeeSkeleton:
            self.drawPoints(qp)
        qp.end()

    def drawPoints(self, qp):
        qp.setPen(qtg.QColor(0, 255, 0, 255))
        size = self.size()

        if size.height() <= 1 or size.height() <= 1:
            return

        for i in range(1000):
            x = random.randint(1, size.width() - 1)
            y = random.randint(1, size.height() - 1)
            qp.drawRect(x, y, 3, 3)

    #Button Functionality
    def pressed(self):
        if self.draw_points.isChecked():
            self.canSeeSkeleton = True
            self.update()
        else:
            self.canSeeSkeleton = False
            self.update()

#Initialize
app = qtw.QApplication([])
mw = MainWindow()

#Run App
app.exec_()