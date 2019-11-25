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
from keras.preprocessing.image import ImageDataGenerator
from sklearn.svm import SVC
from keras.utils import to_categorical
from keras.callbacks import EarlyStopping, ModelCheckpoint

baseDir =os.path.dirname(os.path.abspath('__file__'))
faceDetect = cv2.CascadeClassifier( baseDir + '/haarcascades/haarcascade_frontalface_alt2.xml')
#store_path = r'/Users/ks250082/Documents/python3.5/New_faceDetection/FacesDB/'
store_path =  baseDir + '/FacesDB/'

print(store_path)

# =============================================================================
# #Training Model...
# =============================================================================
def TrainModel(InputFolder):
    
    print('Started Training\n')
    fn = LandmarkTraininng()
    fn.training()
    fn.saveModel()
    cv2.destroyAllWindows()
    #os.mkdir("kapatn")
#else:
 #   print('Exiting the program....!')
  #  cv2.destroyAllWindows()
#TrainModel("/Users/ks250082/Documents/python3.5/New_faceDetection/")
