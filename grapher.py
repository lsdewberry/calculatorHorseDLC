from cProfile import label
import sys
from xml.etree.ElementTree import tostring

import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure
from matplotlib.axis import Axis

import pandas as pd
import csv
import string

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

        #create an empty data frame using pandas API
        self.data_frame = pd.DataFrame()

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

        #create a combo-box to control plotted variables
        self.cb = qtw.QComboBox()
        self.cb.activated[str].connect(self.change_plotted_data)

        #add widgets to layout
        graphLayout = qtw.QVBoxLayout()
        #graphLayout.addWidget(self.graph_label)
        graphLayout.addWidget(self.plot)
        graphLayout.addWidget(self.cb)
        graphLayout.addWidget(self.openBtn)
        self.setLayout(graphLayout)


    #Open CSV data, Plot on Graph
    def open_file(self):
        filename, _ = qtw.QFileDialog.getOpenFileName(self, "Open CSV Data")

        if filename:
            #load data into pandas dataframe
            self.data_frame = pd.read_csv(filename)

            #clean data by combining labels and reindexing
            bodyparts_labels = self.data_frame.loc[0]
            coords_labels = self.data_frame.loc[1]
            labels = [i + "_" + j for i, j in zip(bodyparts_labels, coords_labels)]
            self.data_frame.columns = labels
            self.data_frame = self.data_frame.iloc[2: , : ]
            self.data_frame.index = range(len(self.data_frame.index))
            self.data_frame.rename({'bodyparts_coords': 'frame_number'}, axis= 'columns', inplace= True)

            #this regex line raises a FutureWarning and could break in later versions of PyQt
            self.data_frame.columns = self.data_frame.columns.str.strip().str.lower().str.replace(' ', '_').str.replace('(', '').str.replace(')', '')
            for col in self.data_frame.columns:
                #convert dtype from object to float64
                self.data_frame[col] = pd.to_numeric(self.data_frame[col],errors = 'coerce')
                #add column label to combo box
                self.cb.addItem(str(col))
            
            self.num_frames = len(self.data_frame.index)
            self.plot.axes.cla()
            self.plot.axes.plot(self.data_frame.iloc[:,0], self.data_frame.iloc[:,0], label = self.data_frame.columns[0])
            self.plot.axes.set_xlabel('Frame Number')
            self.plot.axes.set_ylabel('Pixel Coordinate')
            self.plot.axes.legend()
            self.plot.axes.margins(x = 0)
            self.plot.axes.axvline(x = 0, color = 'r', label = 'current frame')
            
            #self.cb.addItems(self.data_frame.columns)
            self.plot.draw_idle()
    
    #switch the data plotted on the graph
    def change_plotted_data(self, text):
        self.plot.axes.lines.pop(0)
        self.plot.axes.plot(self.data_frame.loc[:,'frame_number'], self.data_frame.loc[:, text], label = text)
        self.plot.axes.lines[0], self.plot.axes.lines[1] = self.plot.axes.lines[1], self.plot.axes.lines[0]
        self.plot.axes.legend()

        #reset y axis range
        miny = min(self.data_frame.loc[:, text])
        maxy = max(self.data_frame.loc[:, text])
        dy = (maxy - miny)*0.1
        self.plot.axes.set_ylim(miny-dy, maxy+dy)

        self.plot.draw_idle()

    #Slide a vertical line along the graph as the video frame changes
    def video_position_changed(self, position):

        #convert from a video position in milliseconds to a frame number
        proportion = position / float(self.video_duration)
        frame = int(proportion * self.num_frames)

        if self.plot.axes.lines:
            self.plot.axes.lines.pop()
            self.plot.axes.axvline(x = frame, color = 'r', label = 'current frame')
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
            self.plot.axes.axvline(x = event.xdata, color = 'r', label = 'current frame')
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
            scale_factor = 1/1.5 # <-------- change this to change magnitude of zoom
        elif event.button == 'down':
            # deal with zoom out
            scale_factor = 1.5 # <----------
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