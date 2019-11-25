
# import the necessary packages
from imutils.video import VideoStream
from imutils import face_utils
import imutils
import dlib,time,cv2,os


FILE_OUTPUT = ('DriverExpression.avi')
def assure_path_exists(FILE_OUTPUT):
	dir = os.path.dirname(FILE_OUTPUT)
	if not os.path.exists(dir):
		os.makedirs(dir)
		

shape_predictor="shape_predictor_68_face_landmarks.dat" 
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(shape_predictor)

cam = cv2.VideoCapture(0)
# Get current width of frame
width = cam.get(cv2.CAP_PROP_FRAME_WIDTH)   
# Get current height of frame
height = cam.get(cv2.CAP_PROP_FRAME_HEIGHT) 

   
# Define the codec and create VideoWriter object
fourcc = cv2.VideoWriter_fourcc(*"MJPG")
out = cv2.VideoWriter(FILE_OUTPUT, fourcc, 30,
            (int(width), int(height)), True)
#fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')
#out = cv2.VideoWriter(FILE_OUTPUT,fourcc, 10.0, (int(width),int(height)))

j=0
p=[(0,0)]*68
p1=[(0,0)]*68
d=[(0,0)]*68
dist_smilo=0
dist_yawn=0
dist_lx1=0
dist_lx2=0
dist_ly1=0
dist_ly2=0
dist_rx1=0
dist_rx2=0
dist_ry1=0
dist_ry2=0
dist_x1 =0
dist_x2 =0
dist_y1=0
dist_y2=0
dist_ango=0
dup1,dup2=0,0
diff_chx,diff_chy=0,0
cons_frame = 12
Close = 0
Count = 0
pid=0
LEar=0
REar=0
#Sleepy_count=0 
Ang_cons_frame = 12
#Count_Ang = 0 
angr = 0
Yawnn = 0
Yawn_count = 0
count_smile,count_eact,count_be=0,0,0
# loop over the frames from the video stream
while True:
        # grab the frame from the threaded video stream, resize it to
        # have a maximum width of 400 pixels, and convert it to
        # grayscale
        ret, frame = cam.read()
        #print(frame.shape)
		
        if frame is None:
            print("none")
            break
        #frame = imutils.resize(frame, width=400)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # detect faces in the grayscale frame
        rects = detector(gray, 0)
        diff_smile=0
        diff_ang=0
        diff_leye=0
        diff_eye=0
        diff_reye=0
        diff_up=0
        diff_change=0
        if j%2==0:
                p=p1
                p1=[(0,0)]*68
                d=[(0,0)]*68
        cv2.imshow("Frame", frame)
        # loop over the face detections
        x49=0
        y49=0
        x55=0
        y55=0
        x23=0
        y23=0
        x22=0
        y22=0
        x38=0
        y38=0
        x42=0
        y42=0
        x44=0
        y44=0
        x48=0
        y48=0
        print('count_eact,count_smile,count_be',count_eact,count_smile,count_be)
        '''if count_eact>3:
                #pygame.mixer.music.load('Smile.mp3')
                #pygame.mixer.music.play(-1)
				cv2.putText(frame , "Smiling" , (x,y) ,cv2.FONT_HERSHEY_SIMPLEX, 0.3, (0, 0, 255), 1) 
				print(Smiling)
                count_eact=0
        elif count_smile>3:
                #pygame.mixer.music.stop()
                count_smile=0'''
        e,s,le,re,be=0,0,0,0,0
        for rect in rects:
                # determine the facial landmarks for the face region, then
                # convert the facial landmark (x, y)-coordinates to a NumPy
                # array
                

                shape = predictor(gray, rect)
                shape = face_utils.shape_to_np(shape)

                # loop over the (x, y)-coordinates for the facial landmarks
                # and draw them on the image
                i=1
                print('iter'+str(j))
                x1,y1,w,h=0,0,0,0
                j=j+1
                for (x, y) in shape:
                        #print(i)
                        cv2.circle(frame, (x, y), 1, (0, 0, 255), -1)

                        #print(x,y)
                        if(i):
                                cv2.putText(frame, str(i), (x, y),cv2.FONT_HERSHEY_SIMPLEX, 0.3, (0, 0, 255), 1)
                        #if j==1:
                        if i==1:
                                x1=x
                                y1=y-40
                                
                                
                                if j%2!=0:
                                        dup1=x1
                                        dup2=y1
                                        #print('dup',dup1,dup2)
                                        diff_chx,diff_chy=0,0
                                else:
                                        diff_chx=dup1-x1
                                        #print(dup1)
                                        
                                        #print('change',diff_chx)
                                        diff_chy=dup2-y1
                                        #print(dup2)
                                        
                                        #print('change',diff_chy)
                                

                        elif i==9:
                                h=y-y1
                        elif i==17:
                                w=x-x1

                        elif i==20:
                                if j%2!=0:
                                        y_20=y-y1
                                        print(y_20)
                                else:
                                        y20=y-y1
                                        diff_up=y_20-y20
                                        print(y20,diff_up)
                                        
                                
                        
                        elif(i==49):
                                x49=x
                                y49=y
                        elif(i==55):
                                x55=x
                                y55=y
                                dist_smile=((x49-x55)**2+(y49-y55)**2)**0.5
                                print('dist-smile',dist_smile)
                                diff_smile=(dist_smile)-dist_smilo
                                if diff_smile<0:
                                        diff_smile*=-1

                                print('diff-smile',diff_smile)
                                
                                print('dist-smilo',dist_smilo)
                                if j==1 or diff_smile>15:
                                        dist_smilo=dist_smile
                                        
                                        
                                if diff_smile<6:
                                        dist_smilo=(dist_smilo+dist_smile)//2

                        elif(i==38):
                                x38=x
                                y38=y
                        elif(i==42):
                                x42=x
                                y42=y
                                dist_lx1=((x38-x42)**2+(y38-y42)**2)**0.5
                                #print('dist-lefteye',dist_lx1)
                        elif(i==39):
                                x39 = x
                                y39 = y
                        elif(i==41):
                                x41 = x
                                y41 = y
                                dist_lx2 = ((x38 - x41)**2 + (y41 - y41)**2)**0.5
                                #print('dist-lefteye1',dist_lx2)
                                dist_x1 = dist_lx1 + dist_lx2
                        elif(i==37):
                                x37 = x
                                y37 = y
                        elif(i==40):
                                x40 = x
                                y40 = y
                                dist_y1 = 2 * (((x37 - x40)**2 + (y37-y40)**2)**0.5)
                                #print('dist_y',dist_y1)
                                #diff_leye=(dist_leye)-dist_leyeo
                                LEar = dist_x1 / dist_y1
                                print('LEyeRatio' ,LEar) 								
                                #if LEar<0.25:
                                        #diff_leye=diff_leye*-1

                                #print('diff-leye',diff_leye)
								
                                
                                    #print('dist-leyeo',LEar)
                                #if j==1 or diff_leye>2:
                                        #dist_leyeo=dist_leye
                                        
                                        
                                #if diff_leye<1:
                                        #dist_leyeo=(dist_leyeo+dist_leye)//2                                
                        elif(i==44):
                                x44=x
                                y44=y
                        elif(i==48):
                                x48=x
                                y48=y
                                dist_rx1=((x44-x48)**2+(y44-y48)**2)**0.5
                        elif(i==45):
                                x45 = x
                                y45 = y
                        elif(i==47):
                                x47 = x
                                y47 = y
                                dist_rx2 = ((x45-x47)**2+(y45-y47)**2)**0.5
                                dist_x2 = dist_rx1+dist_rx2
                                #print('dist_x',dist_x2)
                        elif(i==43):
                                x43 = x
                                y43 = y
                        elif(i==46):
                                x46 = x
                                y46 = y
                                dist_y2 = 2 * (((x43 - x46)**2 + (y43-y46)**2)**0.5)
                                #print('dist_y2',dist_y2)
                                REar = dist_x2/dist_y2
						        
								
                                print('RightEyeRatio',REar)
                                #diff_reye=(dist_reye)-dist_reyeo

                                #if REar<0.25:
                                        #diff_reye=diff_reye*-1

                                #print('diff-reye',diff_reye)
                                
                                    #print('dist-reyeo',REar)
                                #if j==1 or diff_reye>2:
                                    #dist_reyeo=dist_reye
                                    #print('check both')
                                    #print(diff_leye,diff_reye)
								# Check if both eyes are closed
								# Average out 
                                Close = (LEar + REar)/2.0
                                print('Ear' , Close)
                                if Close <0.25:
                                    Count = Count +1
                                else:
                                    Count = 0
								
								
                                if (Count >= cons_frame):
                                    cv2.putText(frame,"not - safe , You might feeling sleepy" , (10,30),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                                    #Sleepy_count = Sleepy_count+1
                                    c = 0
								
								
                                #diff=(dist_reye-dist_leye)-(dist_reyeo-dist_leyeo)
                                #if diff<0:
                                        #diff=diff*-1
								# Check if both eyes are closed
								# Average out 
                                #if diff_leye+diff_reye>2 and diff_leye+diff_reye<4 and (diff<0.5):
                                        #print('check both')
                                        #diff_eye=1
                                        
                                #'''if diff_leye>2.5 and diff_reye>2.5 and j!=1:
                                        #print('check both')
                                        #print(diff_leye,diff_reye)'''
                                        
                                #if diff_reye<1:
                                        #dist_reyeo=(dist_reyeo+dist_reye)//2   
        
                        elif(i==22):
                                x22=x
                                y22=y
                        elif(i==23):
                                x23=x
                                y23=y
                                dist_ang=((x22-x23)**2+(y23-y23)**2)**0.5
                                print('dist-ang',dist_ang)
                                if dist_ang<14:
                                    print('Angry', dist_ang)
                                    cv2.putText(frame, 'Angry' , (50,50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 1)
                                    angr = angr+1
                                else:
                                    angr = 0
									
                                if  (angr >= Ang_cons_frame):
                                    cv2.putText(frame,"Please Calm Down" , (10,30),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                                    #Count_Ang = Count_Ang+1 
                                    #print(Count_Ang)
                                    c2 = 0
								
									
								
                                        #diff_ang*=-1

                               #print('diff-ang',diff_ang)
                                
                                #print('dist-ango',dist_ango)
                                #if j==1:
                                        #dist_ango=dist_ang
                                        
                                        
                                #if diff_ang<=5:
                                        #dist_ango=(dist_ango+dist_ang)//2'''
                        #print('j',j)
                        
                        elif(i==63):
                                 x63=x
                                 y63=y
                        elif(i==67):
                                 x67=x
                                 y67=y
                                 dist_yawn=((x63-x67)**2+(y63-y67)**2)**0.5
                                 print('yawn',dist_yawn)
                                 if dist_yawn>15:
                                     print('Yawn',dist_yawn)
                                     cv2.putText(frame,'Yawning' , (50,50) , cv2.FONT_HERSHEY_SIMPLEX,1.2,(0,255,0),1)
                                     Yawnn = Yawnn+1
                                 if (Yawnn >= cons_frame):
                                    cv2.putText(frame,"not - safe , You are feeling sleepy" , (10,30),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                                    #Yawn_count = Yawn_count+1
                                    c = 0									 
                        
                        #cv2.rectangle(frame,(x1,y1),(x1+w,y1+h),(255,0,0),2)5
                        if diff_chx<10 and diff_chy<10:
                                
                                if diff_smile>10 and diff_smile<50 and j!=1:
                                        cv2.putText(frame,'Smile', (50, 50),cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 255), 1)
                                        s=1
                                        #cv2.imshow("selfie1", frame)

                                elif diff_up>3:
                                        cv2.putText(frame,'eye act', (50, 50),cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 255), 1)
                                        e=1

                                #elif diff_eye==1: #2.5<diff_reye<5 and 2.5<diff_leye<5:
                                        #cv2.putText(frame,'Botheye', (50, 50),cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 255), 1)
                                        #print('Botheye')
                                        #be=1

                                        #os.system("notepad")
                                #elif diff_leye>2.5 and diff_leye<5:
                                        
                                        #pid=os.getpid()
                                        #print(pid)
                                        
                                        #cs=VideoStream(src=1).start()
                                        #cv2.putText(frame,'Reye', (50, 50),cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 255), 1)
                                        #le=1
                                        
                                        #time.sleep(5.0)
                                        #fr = cs.read()
                                        #cv2.imshow("selfie1", frame)
                                        #VideoStream(src=1).stop()
                                        #os.kill(pid,signal.SIG_DFL)
#'''capture = CaptureFromCAM(1)  # 0 -> index of camera
                                        #if capture:     # Camera initialized without any errors
                                           #NamedWindow("cam-test",CV_WINDOW_AUTOSIZE)
                                           #f = QueryFrame(capture)     # capture the frame
                                           #if f:
                                               #ShowImage("cam-test",f)
                                               #WaitKey(0)
                                        
                                        #cam = VideoStream(src=0).start()
                                        frame = cam.read()
                                        #DestroyWindow("cam-test")'''
                                        #'''pygame.camera.init()
                                        #cam = pygame.camera.Camera(pygame.camera.list_cameras()[0])
                                        #cam.start()
                                        #img = cam.get_image()
                                        #pygame.image.save(img, "photo.png")
                                        #pygame.camera.quit()'''
                                                                                
                                        #elif diff_ang>4 and j!=1:
                                                #cv2.putText(frame,'Anger', (50, 50),cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 255), 1)
                                                #print('Anger')

                                elif diff_reye>2.5 and diff_reye<5:
                                        #pygame.mixer.music.stop()
                                        cv2.putText(frame,'Leye', (50, 50),cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 255), 1)
                                        re=1
                                        #cv2.imshow("selfie2", frame)
                                        
                                        #time.sleep(5.0)
                                        #fr = cs.read()
                                        #cv2.imshow("selfie", fr)
                                        #VideoStream(src=1).stop()  
                        #if i==1:
                        #        print(x,y)


                        i=i+1

        if e:
                #pygame.mixer.music.load('Smile.mp3')
                #pygame.mixer.music.play(-1)                
                print('eye act')
                count_eact=count_eact+1
        elif s:
                print('smile')
                count_smile=count_smile+1
        # show the frame
        elif be:
                print('Bothe')
                count_be=count_be+1
        elif le:
                h=1
                #os.startfile('chrome')
                #os.system("%systemroot%\system32\scrnsave.scr /s")
                #exit()
        
        #if out is not None:
         #  out.write(frame)
        cv2.imshow("Frame", frame)
		
       
        key = cv2.waitKey(1) & 0xFF
        #if j==15:
        #        break
        # if the `q` key was pressed, break from the loop
        if key == ord("q"):
                break
 
# do a bit of cleanup
VideoStream(src=0).stop()
cv2.destroyAllWindows()


