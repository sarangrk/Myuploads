#Face Detector
import dlib
from sklearn.preprocessing import MinMaxScaler
import cv2, numpy as np
import pandas as pd
import os 
import pickle
from keras.layers import Dense,Flatten,Dropout,BatchNormalization,Flatten
from keras.callbacks import ReduceLROnPlateau
from keras.optimizers import RMSprop,Adam
from keras.models import Sequential,save_model,load_model
from keras import regularizers
from keras.utils import to_categorical
from sklearn.utils import shuffle
from keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from sklearn.svm import SVC


class LandmarkTraininng ():

    def __init__(self):
        #getting the Model file from the current working directory 
        self.baseDir = os.path.dirname(os.path.abspath('__file__'))
        print(self.baseDir)
        self.faceModel_path = self.baseDir + '/shape_predictor_68_face_landmarks.dat' 
        #print(self.baseDir)
        #gettign the Frontal face area from the image
        self.faceDetector = dlib.get_frontal_face_detector()
        self.y= None
        #getting landmark Points
        self.landMarker = dlib.shape_predictor(self.faceModel_path)
        self.landMarksAll = []
        self.label = []
        self.distanceArray = []
        #self.path= os.path.join(self.baseDir, '/FacesDB/')
        self.path= self.baseDir + '/FacesDB/'
        self.backupDataPath = self.baseDir + '/backupData/'
        #self.modelSavePath = os.path.join(self.baseDir,'/Model/')
        self.modelSavePath = self.baseDir + '/Model/'
        
        self.vec = np.empty([68,2],dtype= int)
        self.dist = []
        self.count = 0
        self.label_dict = {}
        #self.svm = SVC(C=100.0,probability=True, kernel='linear')
        self.svm = SVC(C=100 ,probability=True, gamma='auto', kernel=str(u'linear'),verbose =True)
        #===================================================================+===================================================================+

    def saveModel(self):
        #saving model
        with open(self.modelSavePath + 'SVMModel_distance_for_Face.pkl','wb') as f:
                pickle.dump(self.svm, f)
        #saving labels
        with open(self.modelSavePath + 'Label_Dictionary_latest.pkl','wb') as f:
                pickle.dump(self.label_dict, f)

    def createData(self):
        #print(self.folders)
        for folder in self.folders: #range(20,117):
            #img = i #str(i)+'_char.png'
            print('started :',folder)
            self.images = os.listdir(self.path+'/'+folder +'/')
            print(self.images)
            self.images = [item for item in self.images if item != '.DS_Store']
            for imageName in self.images :
                image = cv2.imread(self.path+'/'+folder +'/' + imageName)
                print(image.shape)
                #filter(None,image)
                #if check == True : #deleing the zero byte images
                    #print(imageName)
                image = cv2.resize(image, (300,300), cv2.INTER_CUBIC)
            
                #if image.shape[0] > 0 and image.shape[1] > 0 :
                    #find the face in the image
                faces = self.faceDetector(image,0)
                print('faces length is :', len(faces) )    
                    #Now storing te landmarks of all te faces
                for i in range (0,len(faces)):
                    newRect = dlib.rectangle( int(faces[i].left() ),
                                            int(faces[i].top() ),
                                            int(faces[i].right() ),
                                            int(faces[i].bottom() )
                            )
                
                    #for every face run landmark detector for gettting shpae
                    markers = self.landMarker(image,newRect)
                    #appending these markers to list
                    self.landMarksAll.append(markers)
                    #print(len(markers.parts()))
                #Getting the coordinates :
                self.vec = np.empty([68,2],dtype= int)
                for b in range(68):
                    self.vec[b][0] = markers.part(b).x
                    self.vec[b][1] = markers.part(b).y
                
        

                self.dist = []
                for x,y in self.vec:
                    for x_next,y_next in self.vec :
                        temp = np.array(np.sqrt((x_next - x)**2 + (y_next - y)**2))
                        self.dist.append(temp.ravel() )
                #print('shape of dist:',np.array(self.dist).shape)
                #self.dist = np.array(self.dist).reshape(68*68)
                #distanceArray.append(np.array(dist,np.float32).transpose())
                self.distanceArray.append(np.array(self.dist).reshape(68*68))
                self.label.append(folder)
            print('done with folder {}'.format(folder))
        return(self.distanceArray, self.label)



    def training(self):
        #print(self.path)

        self.folders = os.listdir(self.path)
        self.folders = [item for item in self.folders if item != '.DS_Store']
        for item in self.folders:
            if item not in self.label_dict:
                self.label_dict[item] = self.count
                self.count+=1
        #self.label_dict = {v:k for k,v in self.label_dict.items()}
        print('label_dictionary is :', self.label_dict)

        if os.path.exists(self.backupDataPath + '/Data.csv'):
            flag = True
            original_Data = pd.read_csv(self.backupDataPath + '/Data.csv')
            y_label = original_Data['0']
            original_Data.columns = pd.to_numeric(original_Data.columns)
            #print(original_Data.tail())
            
            print(y_label.value_counts())
            temp = list(y_label.apply(lambda x : str(x).lower()).unique())

        else:
            flag = False
            temp = []   
        #Getting the required folder
        self.folders = [f for f in self.folders if f.lower() not in temp]
        print(flag)

        #creating label Dictionary 
        #temp = np.unique(np.array(self.label))
        #print('temp contains: ', temp)
       

        
        if len(self.folders) != 0:
            
            for folder in self.folders: #range(20,117):
                #img = i #str(i)+'_char.png'
                print('started :',folder)
                self.images = os.listdir(self.path+'/'+folder +'/')
                #print(self.images)
                self.images = [item for item in self.images if item != '.DS_Store']
                for imageName in self.images :
                    image = cv2.imread(self.path+'/'+folder +'/' + imageName)
                    #print(image.shape)
                    #filter(None,image)
                    #if check == True : #deleing the zero byte images
                        #print(imageName)
                    image = cv2.resize(image, (300,300), cv2.INTER_CUBIC)
                
                    #if image.shape[0] > 0 and image.shape[1] > 0 :
                        #find the face in the image
                    faces = self.faceDetector(image,0)
                    print('faces length is :', len(faces) )    
                    if len(faces) != 0:
                        #Now storing te landmarks of all te faces
                        for i in range (0,len(faces)):
                            newRect = dlib.rectangle( int(faces[i].left() ),
                                                    int(faces[i].top() ),
                                                    int(faces[i].right() ),
                                                    int(faces[i].bottom() )
                                    )
                        
                            #for every face run landmark detector for gettting shpae
                            markers = self.landMarker(image,newRect)
                            #appending these markers to list
                            self.landMarksAll.append(markers)
                            #print(len(markers.parts()))
                        #Getting the coordinates :
                        self.vec = np.empty([68,2],dtype= int)
                        for b in range(68):
                            self.vec[b][0] = markers.part(b).x
                            self.vec[b][1] = markers.part(b).y
                        
                

                        self.dist = []
                        for x,y in self.vec:
                            for x_next,y_next in self.vec :
                                temp = np.array(np.sqrt((x_next - x)**2 + (y_next - y)**2))
                                self.dist.append(temp.ravel() )
                        #print('shape of dist:',np.array(self.dist).shape)
                        #self.dist = np.array(self.dist).reshape(68*68)
                        #distanceArray.append(np.array(dist,np.float32).transpose())
                        self.distanceArray.append(np.array(self.dist).reshape(68*68))
                        self.label.append(folder)
                print('done with folder {}'.format(folder))



            #self.distanceArray, self.label = LandmarkTraininng.createData(self)
            
            '''for folder in self.folders: #range(20,117):
                #img = i #str(i)+'_char.png'
                print('started :' ,folder)
                self.images = os.listdir(self.path+'/'+folder +'/')
                self.images = [item for item in self.images if item != '.DS_Store']
                #elf.images = [item for item in self.images if item.shape]
                #check = True #for valid images
                for imageName in self.images :
                    image = cv2.imread(self.path+'/'+folder +'/' + imageName)
                    #filter(None,image)
                    #if check == True : #deleing the zero byte images
                        #print(imageName)
                    image = cv2.resize(image, (300,300), cv2.INTER_CUBIC)
                
                    if image.shape[0] > 0 and image.shape[1] > 0 :
                        #find the face in the image
                        faces = self.faceDetector(image,0)
                        
                        #Now storing te landmarks of all te faces
                    for i in range (0,len(faces)):
                        newRect = dlib.rectangle( int(faces[i].left() ),
                                                int(faces[i].top() ),
                                                int(faces[i].right() ),
                                                int(faces[i].bottom() )
                                )
                    
                        #for every face run landmark detector for gettting shpae
                        
                        markers = self.landMarker(image,newRect)
                        
                        #appending these markers to list
                        self.landMarksAll.append(markers)
                        
                        #print(len(markers.parts()))
                
                    #Getting the coordinates :
                    self.vec = np.empty([68,2],dtype= int)
                    for b in range(68):
                        self.vec[b][0] = markers.part(b).x
                        self.vec[b][1] = markers.part(b).y
                    
            

                    self.dist = []
                    for x,y in self.vec:
                        for x_next,y_next in self.vec :
                            temp = np.array(np.sqrt((x_next - x)**2 + (y_next - y)**2))
                            self.dist.append(temp.ravel() )
                    #print('shape of dist:',np.array(self.dist).shape)
                    #self.dist = np.array(self.dist).reshape(68*68)
                    #distanceArray.append(np.array(dist,np.float32).transpose())
                    self.distanceArray.append(np.array(self.dist).reshape(68*68))
                    self.label.append(folder)
                #print('lenth of Labels is {} and Distance Matrix is {}'.format(len(self.label), np.array(self.distanceArray).shape ))
                print('done with folder {}'.format(folder))
            '''
            print(self.label_dict)
            if flag == False: # 1st time operation of creating backup
                
                data = pd.DataFrame(self.distanceArray)
                data.columns = pd.to_numeric(data.columns)
                
                y = pd.DataFrame(self.label,columns = ['Label'])
                print(y['Label'].value_counts())
                y['Encoded'] = y['Label'].apply(lambda x : self.label_dict[x])
                #merging both DATAFRAME and creating the backup
                data = pd.concat([y[['Label','Encoded']], data],axis=1,ignore_index=True)
                data.tail()
                data.columns = pd.to_numeric(data.columns)
                #Writing file to backup drive
                data.to_csv(self.backupDataPath + '/Data.csv', index=False)  

            else: # backup already exist and not a first time operation 
                data = pd.DataFrame(self.distanceArray)
                data.columns = pd.to_numeric(data.columns)

                y = pd.DataFrame(self.label,columns = ['Label'])
                print(y['Label'].value_counts())
                y['Encoded'] = y['Label'].apply(lambda x : self.label_dict[x])
                #merging both DATAFRAME and creating the backup
                data = pd.concat([y[['Label','Encoded']], data],axis=1,ignore_index=True)
                data.columns = pd.to_numeric(data.columns)
                #merging with original data
                data = pd.concat([original_Data,data],axis=0,ignore_index=True)
                data.to_csv(self.backupDataPath + '/Data.csv',index=False)  

        else:
            data = original_Data
            
        '''self.y_label = pd.DataFrame(self.label,columns=['Label'])
        self.y_label['Encoded'] = self.y_label['Label'].apply(lambda x : self.label_dict[x])
        print(self.y_label['Encoded'].value_counts())'''

        #Scaling the data to range 0 and 1 for Neural network
        #X = self.distanceArray
        #scale = MinMaxScaler()
        #scale.fit(X)
        #X = scale.transform(X)
        y = data[0]
        X = data.drop([0,1],axis=1)
        
            
        # we have two varibales distanceArray and y['Encoded'] 
        #Training the SVM classifier
        print('Starting Training... It might take some time.. ')
        #self.svm.fit(self.distanceArray, self.y['Encoded'])
        self.svm.fit(np.array(X),y)
        print('Done with Training.')

        # =============================================================================
        # # Saving the model and Label Dictionary 
        # =============================================================================
        
        LandmarkTraininng.saveModel(self)
        '''with open(self.modelSavePath + 'SVMModel_distance_for_Face.pkl','wb') as f:
                pickle.dump(self.svm, f)
            

        with open(self.modelSavePath + 'Label_Dictionary.pkl','wb') as f:
                pickle.dump(self.label_dict, f)'''
        print('Model/files saved at {}'.format(self.modelSavePath))

        # =============================================================================
        # 
        # path = r'/Users/vk250027/Documents/FaceDetection/Face_Detection/Models/'
        # 
        # reduceLR= ReduceLROnPlateau(monitor='val_loss', factor=0.1, patience=3, verbose=1, mode='auto',
        #                             epsilon=1e-4, cooldown=0, min_lr=0)
        # 
        # EarlyCheckPt = EarlyStopping(monitor='val_loss', min_delta=0, patience=6, verbose=1, mode='auto')
        # 
        # ModelCkPt = ModelCheckpoint(path +'Dist_Face(24-5-18)_NN.h5', monitor='val_loss', verbose=1, save_best_only=True, save_weights_only=False, mode='auto', period=1)
        # 
        # #creating one hot encoding
        # y_oneHotEncoded = to_categorical(y['Encoded'],len(label_dict))
        # distanceArray, y_oneHotEncoded = shuffle(distanceArray, y_oneHotEncoded,random_state=120)
        # 
        # 
        # model = Sequential()
        # model.add(Dense(512,activation='relu',kernel_regularizer=regularizers.l2(0.001),
        #                  input_shape = [X.shape[1]], name='1st'))
        # 
        # model.add(Dropout(0.2,name='2nd'))
        # model.add(Dense(512,activation='relu',kernel_regularizer=regularizers.l2(0.001),
        #                  name='3rd'))
        # model.add(Dropout(0.2,name='4th'))
        # model.add(Dense(512,activation='relu',kernel_regularizer=regularizers.l2(0.001),
        #                  name='5th'))
        # model.add(Dropout(0.2,name='6th'))
        # #model.add(Flatten(name='Flat_Layer'))
        # 
        # model.add(Dense(len(label_dict), activation='softmax', kernel_regularizer=regularizers.l2(0.001),
        #                  name='LAST'))
        # 
        # model.compile(optimizer='adam',loss='categorical_crossentropy', metrics = ['accuracy'] )
        # print(model.summary())
        # 
        #  
        # hist = model.fit(X,y_oneHotEncoded,epochs=60, batch_size=16,
        #                  callbacks=[reduceLR, EarlyCheckPt, ModelCkPt], validation_split=0.15 )
        #  
        # =============================================================================
        
    '''def testing(self, image):

        # =============================================================================
        #  Testing the Model
        # =============================================================================
        with open(self.modelSavePath + 'SVMModel_distance_for_Face.pkl','rb') as f:
            m = pickle.load(f)
            
            
        #--------

        #img = cv2.imread(r'/Users/vk250027/Documents/FaceDetection/Face_Detection/Scripts/Test/219 4.01.15 PM.jpg')  
        img = cv2.resize(image, (300,300), cv2.INTER_CUBIC)
        self.faces = self.faceDetector(image,0)    

        #landMarksAll = []

        for i in range (0,len(self.faces)):
            newRect = dlib.rectangle( int(self.faces[i].left() ),
                                    int(self.faces[i].top() ),
                                    int(self.faces[i].right() ),
                                    int(self.faces[i].bottom() )
                    )
        markers = self.landMarker(image,newRect)
        vecTest = np.empty([68,2],dtype= int)
                
        for b in range(68):
            vecTest[b][0] = markers.part(b).x
            vecTest[b][1] = markers.part(b).y

        dist = []
        #distanceArrayTest = []
        for x,y in vecTest:
            for x_next,y_next in vecTest :
                temp = np.array(np.sqrt((x_next - x)**2 + (y_next - y)**2))
                dist.append(temp.ravel())
        #print(len(dist))
        dist = np.array(dist).reshape(1,len(dist))
        #dist = dist.reshape(1,len(dist))
        p = m.predict(dist)
        return([k for k,v in self.label_dict.items() if v == p])
'''
