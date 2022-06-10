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
        
        self.videoplayer = vid.VideoPlayer()
        self.videoplayer.setMinimumSize(480,270)
        
        self.graph = grapher.DataDisplay()
        self.graph.setMinimumSize(480, 270)

        splitter = qtw.QSplitter()
        splitter.addWidget(self.videoplayer)
        splitter.addWidget(self.graph)

        outerLayout = qtw.QVBoxLayout()
        outerLayout.addWidget(splitter)
        self.setLayout(outerLayout)

        self.update()
        self.show()


#Initialize
app = qtw.QApplication([])
mw = MainWindow()

#Run App
app.exec_()