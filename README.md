# calculatorHorseDLC
Use to extract common measurements from the excel output from DLC of horses walking across the video.

If your DeepLabCut output excel files are in the specific setup with specific labeled body parts, you should be able to just run DLCread_horse. It imports the excel files in a selected folder (coded in the begining of DLCread_horse) using import_horse, then calculates many things and provides 2 'output' variables: output (a large structure with many different data types), and horseReqOut(a smaller simpler subset of data that was requested to be output).

A lot of updates have been made to 'calculatorRatDLC' that haven't made it to this one (better floor calculations, better toe-off locating)
