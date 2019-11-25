import cv2
import os
import sys 

def objectCount(inputfilename, outputfilename):
    

    #backsub = cv2.bgsegm.createBackgroundSubtractorMOG() #background subtraction to isolate moving cars from line one 
    backsub = cv2.createBackgroundSubtractorKNN()
    #capture = cv2.VideoCapture("/Users/ks250082/Documents/python3.5/Object_count/video.avi") 
    capture = cv2.VideoCapture(inputfilename) 
    i = 0
    counter=0
    s=0
    minArea=1
    
    FILE_OUTPUT =(r'./outputVideo/DemoRecording.mp4')
    #Get current width of frame
    width = capture.get(cv2.CAP_PROP_FRAME_WIDTH)
    #Get current height of frame
    height = capture.get(cv2.CAP_PROP_FRAME_HEIGHT)
    
    fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')
    out = cv2.VideoWriter(outputfilename,fourcc, 10.0, (int(width),int(height)))
    
    while True:
        ret, frame = capture.read()
        
        if (ret == False):
          break
        fgmask = backsub.apply(frame, None, 0.01)
        erode=cv2.erode(fgmask,None,iterations=3)     #erosion to erase unwanted small contours
        moments=cv2.moments(erode,True)               #moments method applied
        area=moments['m00']    
        if moments['m00'] >=minArea:
            x=int(moments['m10']/moments['m00'])
            y=int (moments['m01']/moments['m00'])
            #print("in for loop ...")
            if x>40 and x<55 and y>50 and y<65:       #range of line coordinates for values on left lane
                i=i+1
                print(i)
                
            elif x>102 and x<110 and y>105 and y<130: #range of line coordinatess for values on right lane
                i=i+1
                #print(i)
                #print("in else part")
        #print(x,y)
            cv2.putText(frame,'Object Count %r' %i, (0,20), cv2.FONT_HERSHEY_SIMPLEX,
                            1, (0, 0, 255), 1)
            #cv2.imshow("Track", frame)
            #cv2.imshow("baclkground sub", fgmask)
            out.write(frame)
        #key = cv2.waitKey(100)
        #if key == ord('q'):
         #       break
    capture.release()
#cv2.destroyAllWindows()


