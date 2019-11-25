import cv2,numpy as np, pickle, pandas as pd
import dlib
#from face_embeddings import getEmbedding
from keras.models import load_model
import time

#loading teh model 
#faceDetect = cv2.CascadeClassifier(r'/Users/vk250027/Documents/FaceDetection/Face_Detection/haarcascades/haarcascade_frontalface_alt2.xml')

faceModel_path = 'shape_predictor_68_face_landmarks.dat'
FILE_OUTPUT = r'DemoRecording.mp4'
#faceModel_path =(r'/Users/ks250082/Documents/python3.5/New_faceDetection/shape_predictor_68_face_landmarks.dat')
#FILE_OUTPUT = (r'/Users/ks250082/Documents/python3.5/New_faceDetection/DemoRecording.mp4')
#gettign the Frontal face area from the image
faceDetector = dlib.get_frontal_face_detector()

#getting landmark Points
landMarker = dlib.shape_predictor(faceModel_path)



# =============================================================================
# trainer = cv2.face.EigenFaceRecognizer_create()
# #trainer = cv2.face.LBPHFaceRecognizer_create()
#
# =============================================================================
# =============================================================================
with open(r'/Users/ks250082/Documents/python3.5/New_faceDetection/Model/SVM_Distance_forFace_v1.pkl','rb') as f:
    model = pickle.load(f)
# 

# =============================================================================
# =============================================================================
# Loading labels
# =============================================================================
with open(r'/Users/ks250082/Documents/python3.5/New_faceDetection/Model/Label_Dictionary_v1.pkl','rb') as f:
    label = pickle.load(f)

label = {v:k for k,v in label.items()}

# =============================================================================
# cap = cv2.VideoCapture(0)
# 
# while (True):
#     
#     ret,frame = cap.read()
#     gray = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
#     faces = faceDetect.detectMultiScale(gray,scaleFactor=1.5,minNeighbors=5)
#     
#     for (x,y, w, h) in faces :
#         roi_color = frame[y:y+h,x:x+w]
#         roi_gray = gray[y:y+h,x:x+w]
#         
#         id_,conf = trainer.predict(roi_gray)
#         
#         print(id_)
#         cv2.rectangle(frame,(x,y),(x+w,y+w),(255,0,0),2)
#         cv2.putText(frame,label[id_],(x,y),cv2.FONT_HERSHEY_SIMPLEX,(0,255,0),2)
#         
#     cv2.imshow('fame',frame)
#         
#     if cv2.waitKey(20) & 0xFF == ord('q'):
#         break
# 
# cap.release()
# cv2.destroyAllWindows() 
#         
# =============================================================================

cap = cv2.VideoCapture(0)
#cap = cv2.VideoCapture(r'/Users/ks250082/Documents/python3.5/New_faceDetection/input2.mp4')
#Get current width of frame
width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)  
#Get current height of frame
height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
#

fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')
out = cv2.VideoWriter(FILE_OUTPUT,fourcc, 10.0, (int(width),int(height)))

while (True):
    
    ret,frame = cap.read()
    #frame = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
    #faces = faceDetect.detectMultiScale(frame,scaleFactor=1.5,minNeighbors=5)
    faces = faceDetector(frame,0)
    landMarksAll = []
    print('Faces found :- ',len(faces))
    for i in range (0,len(faces)):
        newRect = dlib.rectangle(int(faces[i].left() ),
                                    int(faces[i].top() ),
                                    int(faces[i].right() ),
                                    int(faces[i].bottom() )
                                )

        #Getting x,y,w,h coordinate
        x = newRect.left()
        y = newRect.top()
        w = newRect.right() - x
        h = newRect.bottom() - y
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
        

        #for every face run landmark detector for gettting shpae
        markers = landMarker(frame,newRect)
        #appending these markers to list
        landMarksAll.append(markers)
        #print(len(markers.parts()))

        #Getting the coordinates :
        vec = np.empty([68,2],dtype= int)
        
        for b in range(68):
            vec[b][0] = markers.part(b).x
            vec[b][1] = markers.part(b).y
            
        dist = []
        for x,y in vec:
            for x_next,y_next in vec :
                temp = np.array(np.sqrt((x_next - x)**2 + (y_next - y)**2))
                dist.append(temp.ravel() )
            
        dist =  np.array(dist).reshape(1,len(dist)) 
        
        p = model.predict(dist)[0]
        prob = model.predict_proba(dist)[0]
        prob1 = (1-prob[0])
        person = label[p]
        print('{} : {}'. format(person,prob[0]))
        print('{}'.format(person) )
        print(1-prob[0])
        #print(person)
        text = person + str(prob1)
        #text = person
        Text1='Unklnown'
        if (prob1 > .9):
            cv2.putText(frame, text, (x, y), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
        else:
            cv2.putText(frame, Text1, (x, y), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
                
    #time.sleep(1)
        #ist = np.array(dist).reshape(68*68)
        #distanceArray.append(np.array(dist,np.float32).transpose())
        #distanceArray.append(dist)
        #label.append(folder)
    #for (x,y, w, h) in faces :
     #   roi_color = frame[y:y+h,x:x+w]
        #roi_gray = gray[y:y+h,x:x+w]
        
        #roi = cv2.resize(roi_color,(350,350), interpolation = cv2.INTER_CUBIC)
        #face_embedding = getEmbedding(roi)
        #print(np.array(face_embedding).shape)
        
        #id_,conf = trainer.predict(roi_gray)
        #print(id_ , ' : ', conf)
        #print(np.array(face_embedding).shape)
        #roi = np.array(face_embedding).reshape(1,#len(face_embedding),
        #              face_embedding.shape[0] * face_embedding.shape[1] )
        #roi = np.array(face_embedding).reshape(1,len(face_embedding),128)
        
        #face_prob = model.predict_proba(roi)
        #face_prob = -np.sort(-face_prob)[0]    
        #print('Face Probabiliti is : ',face_prob[0])
        #id_ = model.predict_classes(roi)[0]
       # id_ = model.predict(roi)[0]
       # print('Class is : ',id_)
        
        
       # if face_prob[0] < 0.50:
        #    text = 'unkonwn :' + str(face_prob[0])
        #else: 
        #    text = label[id_] + str(face_prob[0])
        
        #cv2.rectangle(frame,(x,y),(x+w,y+w),(255,0,0),2)
        
        #cv2.putText(frame,text,(x,y),cv2.FONT_HERSHEY_SIMPLEX,1,(0,255,0),2)
        
        
    cv2.imshow('fame',frame)
    out.write(frame)    
    if cv2.waitKey(100) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows() 
        
        
        
        
