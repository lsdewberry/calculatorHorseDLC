import sys
from xml.etree.ElementTree import tostring

import PyQt5.QtWidgets as qtw
import PyQt5.QtGui as qtg

import videoplayer as vid
import grapher

class MainWindow(qtw.QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Horse Data Visualization Tool")
        self.setWindowIcon(qtg.QIcon('window_icon.png'))
        
        self.videoplayer = vid.VideoPlayer()
        self.videoplayer.setMinimumSize(480,270)
        
        self.graph = grapher.DataDisplay()
        self.graph.setMinimumSize(480, 270)

        #ui feature to have resizeable widgets
        splitter = qtw.QSplitter()
        splitter.addWidget(self.videoplayer)
        splitter.addWidget(self.graph)

        outerLayout = qtw.QVBoxLayout()
        outerLayout.addWidget(splitter)
        self.setLayout(outerLayout)

        #supports syncronized scrubbing of graph alongside video
        self.videoplayer.mediaPlayer.positionChanged.connect(self.graph.video_position_changed)
        self.videoplayer.mediaPlayer.durationChanged.connect(self.graph.video_duration_changed)

        self.update()
        self.show()
    #def move_line(self, position):
    #   self.graph.axes


#Initialize
app = qtw.QApplication([])
mw = MainWindow()

#Run App
app.exec_()