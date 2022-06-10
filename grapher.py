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

        #self.setWindowTitle("Horse Data Visualization Tool")
        
        #create a label for the graph
        self.graph_label = qtw.QLabel("Ankle Position by Time")
        self.graph_label.setFont(qtg.QFont(''))
        self.graph_label.setFixedHeight(50)

        #create open-file button
        self.openBtn = qtw.QPushButton('Open CSV Data')
        self.openBtn.clicked.connect(self.open_file)
        
        # Create the maptlotlib FigureCanvas object,
        # which defines a single set of axes as self.axes.
        self.graph = MplCanvas(self, width=5, height=4, dpi=100)
        self.graph.setMinimumSize(480, 270)

        #add widgets to layout
        graphLayout = qtw.QVBoxLayout()
        graphLayout.addWidget(self.graph_label)
        graphLayout.addWidget(self.graph)
        graphLayout.addWidget(self.openBtn)
        self.setLayout(graphLayout)

        self.update()
        self.show()

    #Button Functionality
    def pressed(self):
        pass

    def open_file(self):
        filename, _ = qtw.QFileDialog.getOpenFileName(self, "Open CSV Data")

        if filename != '':
            frame = []
            yPos = []
            with open(filename, 'r') as csvfile:
                lines = csv.reader(csvfile, delimiter=',')
                for row in lines:
                    try:
                        frame.append(float(row[0])) #append the numeric values
                        yPos.append(float(row[2]))
                    except:
                        pass #ignore the nonnumeric values
            
            self.graph.axes.cla()
            self.graph.axes.plot(frame, yPos, label = "Right Front Hoof")
            self.graph.axes.legend()
            self.graph.draw_idle()

#Initialize