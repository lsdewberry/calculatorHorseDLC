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

        self.num_frames = 0
        self.video_duration = 1 #prevents a divde by zero error when video_position_changed initially executes

        self.init_ui()
        self.show()

    def init_ui(self):
        #create a label for the graph
        self.graph_label = qtw.QLabel("Ankle Position by Time")
        self.graph_label.setFont(qtg.QFont(''))
        self.graph_label.setFixedHeight(50)

        #create open-file button
        self.openBtn = qtw.QPushButton('Open CSV Data')
        self.openBtn.clicked.connect(self.open_file)
        
        # Create the maptlotlib FigureCanvas object,
        self.graph = MplCanvas(self, width=5, height=4, dpi=100)
        self.graph.setMinimumSize(480, 270)

        #add widgets to layout
        graphLayout = qtw.QVBoxLayout()
        #graphLayout.addWidget(self.graph_label)
        graphLayout.addWidget(self.graph)
        graphLayout.addWidget(self.openBtn)
        self.setLayout(graphLayout)


    #Open CSV data, Plot on Graph
    def open_file(self):
        filename, _ = qtw.QFileDialog.getOpenFileName(self, "Open CSV Data")

        if filename:
            frames = []
            yPos = []
            with open(filename, 'r') as csvfile:
                lines = csv.reader(csvfile, delimiter=',')
                for row in lines:
                    try:
                        frames.append(float(row[0])) #append the numeric values
                        yPos.append(float(row[2]))
                    except:
                        pass #ignore the nonnumeric values
            
            self.num_frames = len(frames)
            self.graph.axes.cla()
            self.graph.axes.plot(frames, yPos, label = "Right Front Hoof")
            self.graph.axes.legend()
            self.graph.axes.axvline(x = 0, color = 'r', label = 'axvline - full height')
            self.graph.draw_idle()
    
    #Slide a vertical line along the graph as the video frame changes
    def video_position_changed(self, position):

        #convert from a video position in milliseconds to a frame number
        proportion = position / float(self.video_duration)
        frame = proportion * self.num_frames

        if self.graph.axes.lines:
            self.graph.axes.lines.pop()
            self.graph.axes.axvline(x = frame, color = 'r', label = 'axvline - full height')
            self.graph.draw_idle()

    #Store the duration of video in graph object, supports vertical line scrubbing function.
    def video_duration_changed(self, duration):
        self.video_duration = duration