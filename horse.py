import sys
from xml.etree.ElementTree import tostring

import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure

import PyQt5.QtWidgets as qtw
import PyQt5.QtGui as qtg

class MplCanvas(FigureCanvasQTAgg):

    def __init__(self, parent=None, width=5, height=4, dpi=100):
        fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = fig.add_subplot(111)
        super(MplCanvas, self).__init__(fig)

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

        over_label = qtw.QLabel("Horsey!!")
        over_label.setFont(qtg.QFont(''))
        videoLayout.addWidget(over_label)

        toggle_skeleton = qtw.QPushButton("Toggle Skeleton Overlay",
            clicked = lambda: pressed())
        videoLayout.addWidget(toggle_skeleton)
        
        horse_pic = qtw.QLabel()
        horsemap = qtg.QPixmap('horse.jpg')
        skeletonmap = qtg.QPixmap('horse-skeleton.jpg')
        horse_pic.setPixmap(skeletonmap)
        videoLayout.addWidget(horse_pic)

        over_label = qtw.QLabel("Ankle Position by Time")
        over_label.setFont(qtg.QFont(''))
        graphLayout.addWidget(over_label)
        
        # Create the maptlotlib FigureCanvas object,
        # which defines a single set of axes as self.axes.
        sc = MplCanvas(self, width=5, height=4, dpi=100)
        sc.axes.plot([0,1,2,3,4], [10,1,20,3,40])
        graphLayout.addWidget(sc)

        #Button Functionality
        def pressed():
            if horse_pic.pixmap is horsemap:
                horse_pic.setPixmap(skeletonmap)
            else:
                horse_pic.setPixmap(horsemap)

        self.update()
        self.show()

#Initialize
app = qtw.QApplication([])
mw = MainWindow()

#Run App
app.exec_()