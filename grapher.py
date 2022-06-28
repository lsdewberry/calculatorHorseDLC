import sys
from xml.etree.ElementTree import tostring

import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure
from matplotlib.axis import Axis

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
        self.video_duration = 1 #prevents a divide by zero error when video_position_changed initially executes

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
        self.graph.mpl_connect('button_press_event', self.click_graph)
        self.graph.mpl_connect('scroll_event', self.zoom)

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

    def click_graph(self, event):
        if event.inaxes != self.graph.axes: return
        #print("X: ", event.xdata)
        #print("Y: ", event.ydata)
        if self.graph.axes.lines:
            self.graph.axes.lines.pop()
            self.graph.axes.axvline(x = event.xdata, color = 'r', label = 'axvline - full height')
            self.graph.draw_idle()
        
    def zoom(self, event):
        cur_xlim = self.graph.axes.get_xlim()
        #cur_ylim = self.graph.axes.get_ylim()
        cur_xrange = (cur_xlim[1] - cur_xlim[0])*.5
        #cur_yrange = (cur_ylim[1] - cur_ylim[0])*.5
        xdata = event.xdata # get event x location
        #ydata = event.ydata # get event y location
        if event.button == 'up':
            # deal with zoom in
            scale_factor = 1/2.0
        elif event.button == 'down':
            # deal with zoom out
            scale_factor = 2.0
        else:
            # deal with something that should never happen
            scale_factor = 1
        # set new limits
        self.graph.axes.set_xlim([xdata - cur_xrange*scale_factor,
                     xdata + cur_xrange*scale_factor])
        #self.graph.axes.set_ylim([ydata - cur_yrange*scale_factor,
                     #ydata + cur_yrange*scale_factor])
        self.graph.draw_idle()
