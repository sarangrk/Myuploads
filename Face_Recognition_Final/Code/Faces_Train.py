#training the model to identify the faces
#import Face_Detection/face_embeddings.py
#from face_embeddings import getEmbedding
import FaceLandmarks
from FaceLandmarks import LandmarkTraininng

import pickle
import cv2, numpy as np
import os 
from PIL import Image
from keras.layers import Dense, Flatten,Dropout,BatchNormalization
from keras.callbacks import ReduceLROnPlateau
from keras.optimizers import RMSprop,Adam
from keras.models import Sequential,save_model,load_model
from keras import regularizers
from keras.activations import relu
import pandas as pd,numpy as np
import cv2
from sklearn.metrics import classification_report,confusion_matrix
import matplotlib.pyplot as plt
from keras.preprocessing.image import ImageDataGenerator
from sklearn.svm import SVC
from keras.utils import to_categorical
from keras.callbacks import EarlyStopping, ModelCheckpoint

baseDir =os.path.dirname(os.path.abspath('__file__'))
faceDetect = cv2.CascadeClassifier( baseDir + '/haarcascades/haarcascade_frontalface_alt2.xml')
#store_path = r'/Users/ks250082/Documents/python3.5/New_faceDetection/FacesDB/'
store_path =  baseDir + '/FacesDB/'

# =============================================================================
# #Creating a DataBase for new uer
# =============================================================================

txt = input('Do you want to create a new Data ? Y or N:\n', )
mark = True
if type(txt) == str:
    if (txt.lower()) == 'y':
        print('Please stand in front of camera')

        while(mark == True):
            name = str(input('Please mention the name of the person whose Data is to be created..\n',))
            
            if not os.path.isdir(store_path + name):
                os.makedirs(store_path + name)    
            else:
                response = str(input ('Folder Exists. Would you like to add data to existing Folder ? y or n \n', ))
                #while (response  in ['y','Y','n','N'] ):
                if response in ['y','Y','n','N'] :
                    if response.lower() == 'n':
                        #newfilepath = store_path + name + '/'
                        print('creating a new folder with same name : {} '.format(name + str('-copy')))
                        name = name + str('-copy')
                        os.makedirs(store_path + name)
                    else:
                         print('Using the avalibale folder with Name : {}'.format(name))
                      
                        
                else:
                    print('you have not entered correct response.. please re run the program and give correct response...')
                    exit
           
            newfilepath = store_path + name + '/'
            
            cap = cv2.VideoCapture(0)
            counts  = 0
            
            while (counts < 1000):
                ret,frame = cap.read()
                
                #gray = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
                faces = faceDetect.detectMultiScale(frame,scaleFactor=1.5,minNeighbors=5)
                
                if len(faces) > 0:
                    for (x,y, w, h) in faces :
                        roi_color = frame[y-50:y+h+50,x-50:x+w+50]
                        #roi_gray = gray[y:y+h,x:x+w]
                        #store the image 
                        cv2.imwrite(newfilepath + str(counts + 200) + '.jpg' , roi_color)
                        
                        
                        if counts % 50 ==0:
                            print('{} images saved so far..'.format(counts))
                            
                        cv2.rectangle(frame,(x,y),(x+w,y+w),(255,0,0),2)
                cv2.imshow('frame', frame)
                counts+=1
                if cv2.waitKey(20) & 0xFF == ord('q'):
                    break
            
            cap.release()
            #cv2.destroyAllWindows()
            
            check = str(input('Do you want to create another data ? y/n..\n'))
            if check.lower() == 'y':
                mark = True
            else:
                mark = False
            
        if(str(input('proceed with training...? y/n ', )).lower() == 'y'):
            
            print('Started Training\n')
            fn = LandmarkTraininng()
            fn.training()
            #cv2.destroyAllWindows()
            
            #FaceLandmarks.training()    
            #perform_training()
            cv2.destroyAllWindows()
        else:
            print('Exiting the program....!')
            cv2.destroyAllWindows()
                
        
    else : 
        print('Proceeding with Training on availbale Dataset')
        #call training Function
        print('Started Training\n')
        #perform_Training()
        #FaceLandmarks.training() 
        f = LandmarkTraininng()
        f.training()

else:
   print(' Wrong input...! Kindly rerun the Programe and Please Enter in Y or N format only') 



