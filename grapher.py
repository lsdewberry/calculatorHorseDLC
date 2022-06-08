import sys
from xml.etree.ElementTree import tostring

import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure

import csv

import PyQt5.QtWidgets as qtw
import PyQt5.QtGui as qtg

class MplCanvas(FigureCanvasQTAgg):

    def __init__(self, parent=None, width=5, height=4, dpi=100):
        fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = fig.add_subplot(111)
        super(MplCanvas, self).__init__(fig)

class DataDisplay(qtw.QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Horse Data Visualization Tool")
        graphLayout = qtw.QVBoxLayout()


        self.setLayout(graphLayout)

        self.graph_label = qtw.QLabel("Ankle Position by Time")
        self.graph_label.setFont(qtg.QFont(''))
        self.graph_label.setFixedHeight(50)
        graphLayout.addWidget(self.graph_label)
        
        # Create the maptlotlib FigureCanvas object,
        # which defines a single set of axes as self.axes.
        self.sc = MplCanvas(self, width=5, height=4, dpi=100)

        frame = []
        yPos = []
        with open('C0213DLC_resnet50_NewSkeletonMay27shuffle1_1030000.csv', 'r') as csvfile:
            lines = csv.reader(csvfile, delimiter=',')
            for row in lines:

        self.sc.axes.plot([0,1,2,3,4], [10,1,20,3,40])
        self.sc.setMinimumSize(480, 270)
        graphLayout.addWidget(self.sc)

        self.update()
        self.show()

    #Button Functionality
    def pressed(self):
        pass

#Initialize
app = qtw.QApplication([])
mw = DataDisplay()

#Run App
app.exec_()