from multiprocessing.dummy import current_process
from tkinter import HORIZONTAL
from turtle import pos
from PyQt5.QtWidgets import QApplication, QWidget, QPushButton, QHBoxLayout, QVBoxLayout, QLabel, QSlider, QStyle, QSizePolicy, QFileDialog
import sys
from PyQt5.QtMultimedia import QMediaPlayer, QMediaContent
from PyQt5.QtMultimediaWidgets import QVideoWidget
from PyQt5.QtGui import QIcon, QPalette
from PyQt5.QtCore import Qt, QUrl

import grapher

class VideoPlayer(QWidget):
    def __init__(self):
        super().__init__()

        #self.setWindowIcon(QIcon('player.png'))
        self.init_ui()
        
        #member variables to hold video info
        self.duration = 0
        self.position = 0
        self.graph_reference = None

        self.show()

    def init_ui(self):
        #create media player object
        self.mediaPlayer = QMediaPlayer(None, QMediaPlayer.VideoSurface)

        #create a video widget object
        videowidget = QVideoWidget()

        #create open button
        openBtn = QPushButton('Open Video')
        openBtn.clicked.connect(self.open_file)

        #create play button
        self.playBtn = QPushButton()
        self.playBtn.setEnabled(False)
        self.playBtn.setIcon(self.style().standardIcon(QStyle.SP_MediaPlay))
        self.playBtn.clicked.connect(self.play_video)

        #create slider
        self.slider = QSlider(Qt.Horizontal)
        self.slider.setRange(0,0)
        self.slider.sliderMoved.connect(self.set_position)

        #create label
        self.label = QLabel()
        self.label.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Maximum)
        self.labelString = "Frame: {} / {}"
        self.label.setText(self.labelString)

        #create hbox layout
        hboxLayout = QHBoxLayout()
        hboxLayout.setContentsMargins(0,0,0,0)

        #set widgets to the hbox layout
        hboxLayout.addWidget(openBtn)
        hboxLayout.addWidget(self.slider)
        hboxLayout.addWidget(self.playBtn)

        #create vbox layout
        mainLayout = QVBoxLayout()
        mainLayout.addWidget(videowidget)
        mainLayout.addLayout(hboxLayout)
        mainLayout.addWidget(self.label)

        self.setLayout(mainLayout)
        self.mediaPlayer.setVideoOutput(videowidget)

        self.mediaPlayer.stateChanged.connect(self.mediastate_changed)
        self.mediaPlayer.positionChanged.connect(self.position_changed)
        self.mediaPlayer.durationChanged.connect(self.duration_changed)

    def set_graph_reference(self, graph: grapher.DataDisplay):
        self.graph_reference = graph

    def open_file(self):
        filename, _ = QFileDialog.getOpenFileName(self, "Open Video")

        if filename != '':
            self.mediaPlayer.setMedia(QMediaContent(QUrl.fromLocalFile(filename)))
            self.playBtn.setEnabled(True)

    def play_video(self):
        if self.mediaPlayer.state() == QMediaPlayer.PlayingState:
            self.mediaPlayer.pause()
        else:
            self.mediaPlayer.play() 

    def mediastate_changed(self, state):
        if self.mediaPlayer.state() == QMediaPlayer.PlayingState:
            self.playBtn.setIcon(self.style().standardIcon(QStyle.SP_MediaPause))
        else:
            self.playBtn.setIcon(self.style().standardIcon(QStyle.SP_MediaPlay))

    def position_changed(self, position):
        self.slider.setValue(position)
        self.position = position
        if self.graph_reference is not None:
            currFrame = self.labelString.format(self.position, self.graph_reference.num_frames - 1)
            self.label.setText(currFrame)
  
    def duration_changed(self, duration):
        self.slider.setRange(0, duration)
        self.duration = duration
        if self.graph_reference is not None:
            currFrame = self.labelString.format(self.position, self.graph_reference.num_frames - 1)
            self.label.setText(currFrame)

    def set_position(self, position):
        self.mediaPlayer.setPosition(position)
        #print("video_set_position")

    def click_graph(self, event):
        if event.inaxes != self.graph_reference.plot.axes: return
        proportion = event.xdata / float(self.graph_reference.num_frames)
        position = proportion * self.duration
        self.position_changed(int(position))
        self.set_position(int(position))