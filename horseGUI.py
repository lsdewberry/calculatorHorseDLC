import sys
from xml.etree.ElementTree import tostring

import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure

import PyQt5.QtWidgets as qtw
import PyQt5.QtGui as qtg

import videoplayer as vid
import grapher

class MainWindow(qtw.QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Horse Data Visualization Tool")
        outerLayout = qtw.QHBoxLayout()
        videoLayout = qtw.QVBoxLayout()
        graphLayout = qtw.QVBoxLayout()

        outerLayout.addLayout(videoLayout)
        outerLayout.addLayout(graphLayout)
        self.setLayout(outerLayout)

        
        self.over_label = qtw.QLabel("Horsey!!")
        self.over_label.setFont(qtg.QFont(''))
        self.over_label.setFixedHeight(50)
        videoLayout.addWidget(self.over_label)
        

        self.toggle_skeleton = qtw.QPushButton("Toggle Skeleton Overlay")
        self.toggle_skeleton.setCheckable(True)
        self.toggle_skeleton.toggle()
        self.toggle_skeleton.clicked.connect(self.pressed)
        videoLayout.addWidget(self.toggle_skeleton)

        self.videoplayer = vid.VideoPlayer()
        self.videoplayer.setMinimumSize(480,270)
        videoLayout.addWidget(self.videoplayer)
        '''
        self.horse_pic = qtw.QLabel()
        self.horsemap = qtg.QPixmap('horse.jpg')
        self.skeletonmap = qtg.QPixmap('horse-skeleton.jpg')
        self.horse_pic.setPixmap(self.horsemap)
        videoLayout.addWidget(self.horse_pic)
        '''
        
        # Create the maptlotlib FigureCanvas object,
        # which defines a single set of axes as self.axes.
        self.graph = grapher.DataDisplay()
        self.graph.setMinimumSize(480, 270)
        graphLayout.addWidget(self.graph)

        self.update()
        self.show()

    #Button Functionality
    def pressed(self):
        pass

#Initialize
app = qtw.QApplication([])
mw = MainWindow()

#Run App
app.exec_()