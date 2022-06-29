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
        self.plot = MplCanvas(self, width=5, height=4, dpi=100)
        self.plot.setMinimumSize(480, 270)
        self.plot.mpl_connect('button_press_event', self.click_graph)
        self.plot.mpl_connect('scroll_event', self.zoom)

        #add widgets to layout
        graphLayout = qtw.QVBoxLayout()
        #graphLayout.addWidget(self.graph_label)
        graphLayout.addWidget(self.plot)
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
            self.plot.axes.cla()
            self.plot.axes.plot(frames, yPos, label = "Right Front Hoof")
            self.plot.axes.legend()
            self.plot.axes.margins(x = 0)
            self.plot.axes.axvline(x = 0, color = 'r', label = 'axvline - full height')
            self.plot.draw_idle()
    
    #Slide a vertical line along the graph as the video frame changes
    def video_position_changed(self, position):

        #convert from a video position in milliseconds to a frame number
        proportion = position / float(self.video_duration)
        frame = int(proportion * self.num_frames)

        if self.plot.axes.lines:
            self.plot.axes.lines.pop()
            self.plot.axes.axvline(x = frame, color = 'r', label = 'axvline - full height')
            self.plot.draw_idle()
            #print("grapher_vid_pos_change")

    #Store the duration of video in graph object, supports vertical line scrubbing function.
    def video_duration_changed(self, duration):
        self.video_duration = duration

    def click_graph(self, event):
        if event.inaxes != self.plot.axes: return
        #print("X: ", event.xdata)
        #print("Y: ", event.ydata)
        if self.plot.axes.lines:
            self.plot.axes.lines.pop()
            self.plot.axes.axvline(x = event.xdata, color = 'r', label = 'axvline - full height')
            self.plot.draw_idle()
            #print("grapher_click_graph")
        
    def zoom(self, event):
        cur_xlim = self.plot.axes.get_xlim()
        #cur_ylim = self.graph.axes.get_ylim()
        cur_xrange = (cur_xlim[1] - cur_xlim[0])*.5
        #cur_yrange = (cur_ylim[1] - cur_ylim[0])*.5
        xdata = event.xdata # get event x location
        #ydata = event.ydata # get event y location
        if event.button == 'up':
            # deal with zoom in
            scale_factor = 1/2.0 # <-------- change this to change scale of zoom
        elif event.button == 'down':
            # deal with zoom out
            scale_factor = 2.0
        else:
            # deal with something that should never happen
            scale_factor = 1
        # set new limits
        xmin = xdata - cur_xrange*scale_factor
        xmax = xdata + cur_xrange*scale_factor
        if xmin < 0: xmin = 0
        if xmax > self.num_frames: xmax = self.num_frames
        self.plot.axes.set_xlim([xmin, xmax])
        #self.graph.axes.set_ylim([ydata - cur_yrange*scale_factor,
                     #ydata + cur_yrange*scale_factor])
        self.plot.draw_idle()
