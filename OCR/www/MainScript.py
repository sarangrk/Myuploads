#Using Hog values of Images of Alphabets, Digits and few special characters

print("Point 1")
#from  scipy import ndimage
#import re
#import math
#import numpy as np
#import argparse
import cv2
#from math import atan2, pi
import string
import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)
from pandas import ExcelWriter
#import matplotlib.pyplot as plt
#from sklearn.metrics import confusion_matrix, classification_report
#from sklearn.model_selection import train_test_split
#from sklearn.neural_network import MLPClassifier
#from sklearn.ensemble import RandomForestClassifier
import pickle
from keras.models import Sequential, load_model
from keras.preprocessing import image
import os
#os.environ['TF_CPP_MIN_LOG_LEVEL']='3'
#from nltk.tag import pos_tag
#import json
print("Point 2")



#imageFilePath =r'/Users/vk250027/Documents/Bevmo/Images/Input/sample6.jpg'
baseDir = os.path.dirname(os.path.abspath('__file__'))

model_path = baseDir + '/Models/' + 'CnnAa-zZ@_(20-05-18)_ver3.h5'
digit_model_path = baseDir + '/Models/' + 'Digit.h5'

# =============================================================================
# y_labels = {'A': 0,'B': 1,'C': 2,'D': 3,'E': 4,'F': 5,'G': 6,'H': 7,'I': 8,'J': 9,'K': 10,'L': 11,'N': 12,'P': 13,'Q': 14,'R': 15,'S': 16,'T': 17,'U': 18,'V': 19,'W': 20,'X': 21,'Y': 22,'Z': 23,'m': 24,'o': 25,'a': 26,'b': 27,'d': 28,'e': 29,'f': 30,'g': 31,'h': 32,'i': 33,'q': 34,'r': 35,'t': 36}
# =============================================================================
y_labels = {'A': 0, '@': 1, 'B': 2,
 'C': 3,'D': 4,'E': 5,'F': 6,'G': 7,'H': 8,'I': 9, 'J': 10,'K': 11,'L': 12,'N': 13,'P': 14,'Q': 15,
 'R': 16,'S': 17,'T': 18,'U': 19,'_': 20,'V': 21,'W': 22,'X': 23,'Y': 24,'Z': 25,'m': 26,'o': 27,'a': 28,'b': 29,'d': 30, 'e': 31,'f': 32,'g': 33,'h': 34,'i': 35,'q': 36,'r': 37,'t': 38}

# =============================================================================
# y_labels = {'A': 0,  '@': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8, 'I': 9, 'J': 10, 'K': 11, 'L': 12, 'N': 13, 'P': 14, 'Q': 15, 'R': 16, 'S': 17, 'T': 18, 'U': 19, '_': 20, 'V': 21, 'W': 22, 'X': 23, 'Y': 24, 'Z': 25, 'm': 26, 'o': 27, 'a': 28, 'b': 29, 'd': 30, 'e': 31, 'f': 32, 'g': 33, 'h': 34, 'i': 35,
#  'q': 36,
#  'r': 37,
#  't': 38}
# 
# =============================================================================
# =============================================================================
# y_labels = {'A': 0,'B': 1,'C': 2,'D': 3,'E': 4,'F': 5,'G': 6,'H': 7,'I': 8,'J': 9,'K': 10,'L': 11,'N': 12,'P': 13,'Q': 14,'R': 15,'S': 16,'T': 17,'U': 18,'V': 19,'W': 20,'X': 21,'Y': 22,'Z': 23,'m': 24,'o': 25,'a': 26,'b': 27,'d': 28,'e': 29,'f': 30,'g': 31,'h': 32,'i': 33,'q': 34,'r': 35,'t': 36}
# 
# =============================================================================
digitList = list(string.digits)


#list(string.ascii_uppercase)
kernel = np.ones((2,2),np.uint8)
#index = 0
global counts,X,Y,W,H

#Loading Model 

CharModel = load_model(model_path)
digitModel = load_model(digit_model_path)



#------- Functions Definitions---------------------------------------------------------------------

""" def HogDescriptor():
    
    _winSize = (28,28)
    _blockSize = (8,8)
    _blockStride = (4,4)
    _cellSize = (8,8)
    _nbins = 9
    _derivAperture = 1
    _winSigma = -1.
    _histogramNormType = 0
    _L2HysThreshold = 0.2
    _gammaCorrection = 1
    _nlevels = 64
    _signedGradient = True
    
    
    HOG = cv2.HOGDescriptor(_winSize, _blockSize, _blockStride, _cellSize, _nbins, _derivAperture, _winSigma, _histogramNormType, _L2HysThreshold, _gammaCorrection, _nlevels, _signedGradient)
    
    return HOG """

print("Point 3")
def Get_Processed_Image(image):
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    blur = cv2.GaussianBlur(gray_image,(5,5),0)
    ret3,Otsu_Threshold_GaussianBlur_Image = cv2.threshold(blur,0,255,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
    Otsu_Threshold_GaussianBlur_Image = cv2.bitwise_not(Otsu_Threshold_GaussianBlur_Image)
    closing = Otsu_Threshold_GaussianBlur_Image
    #cv2.imwrite(baseDir + '/testDir/'+'Closing.jpg',closing)
    #closing = cv2.morphologyEx(Otsu_Threshold_GaussianBlur_Image, cv2.MORPH_CLOSE, np.ones((2,2),np.uint8))
    #closing = cv2.erode(closing,np.ones((1,1),np.uint8), iterations=1)
    #closing = cv2.dilate(closing,np.ones((2,2),np.uint8), iterations=1)    
    #cv2.imwrite(r'C:\Users\sachin\Desktop\closing.jpg',closing)

    return closing

print("Point 4")

def Get_Dilated_Image(image, number):
    global index
    kernel = np.ones((6,number),np.uint8)
    img_dilation = cv2.dilate(image, kernel, iterations=3)
    for i in range(img_dilation.shape[0]):
        for j in range(img_dilation.shape[1]):
            if img_dilation[i,j] > 10:
                img_dilation[i,j] = 255
    #index = index + 1
    #cv2.imwrite(baseDir + '/testDir/'+'dialted_image.jpg',img_dilation)
    return img_dilation
print("Point 5")        

def Get_Countours(input_Image):
    #cv2.imwrite(baseDir +'/testDir/' + '1stContour.jpg', input_Image) 
    temp_image, contours, hierarchy = cv2.findContours(input_Image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    #cv2.imwrite(baseDir +'/testDir/' + '2ndContour.jpg', input_Image) 
    #cv2.imwrite(baseDir +'/testDir/' + 'tempImage.jpg', temp_image) 
    return contours


def Sort_Countours(cnts, method="left-to-right"):
    # initialize the reverse flag and sort index
    reverse = False
    i = 0

    # handle if we need to sort in reverse
    if method == "right-to-left" or method == "bottom-to-top":
        reverse = True

    # handle if we are sorting against the y-coordinate rather than
    # the x-coordinate of the bounding box
    if method == "top-to-bottom" or method == "bottom-to-top":
        i = 1

    # construct the list of bounding boxes and sort them from top to
    # bottom
    boundingBoxes = [cv2.boundingRect(c) for c in cnts]
    (cnts, boundingBoxes) = zip(*sorted(zip(cnts, boundingBoxes),
                                        key=lambda b:b[1][i], reverse=reverse))

    # return the list of sorted contours and bounding boxes
    return (cnts)

def Draw_Contours(Image, Contours):
    for cnt in Contours:
        x,y,w,h = cv2.boundingRect(cnt)
        #print (str(x) + " - " + str(y)+ " - " + str(w) + " - " + str(h))
        cv2.rectangle(Image,(x,y),(x+w,y+h),(0,0,255),1)
    #cv2.imwrite(r'/Users/vk250027/Documents/Bevmo/Images/Input/Contours.jpg',Image)   


def getNewResizedImage(input_Image, Image_Size):
    height,width = input_Image.shape
    #print (height, width)

    if width > height:
        aspect_Ratio = (float)(width/height)
        width = 20
        height = round(width/aspect_Ratio)
    else:
        aspect_Ratio = (float)(height/width)
        height = 20
        width = round(height/aspect_Ratio)
        
    input_Image = cv2.resize(input_Image, (int(width),int(height)), interpolation = cv2.INTER_AREA )
    
    height,width = input_Image.shape
    
    number_Of_Column_To_Add = 28-width
    temp_Column = np.zeros( (height , int(number_Of_Column_To_Add/2)), dtype = np.uint8)
    input_Image = np.append(temp_Column, input_Image, axis=1)
    input_Image = np.append(input_Image, temp_Column, axis=1)


    height,width = input_Image.shape

    number_Of_Row_To_Add = 28-height
    temp_Row= np.zeros( (int(number_Of_Row_To_Add/2) , width ), dtype = np.uint8)
    input_Image = np.concatenate((temp_Row,input_Image))
    input_Image = np.concatenate((input_Image,temp_Row))

    return cv2.resize(input_Image, (Image_Size,Image_Size), interpolation = cv2.INTER_AREA )

def Get_Text_From_Image(lImage, contours, model, checkFor, Width=5, Height=5 ):

    global count,X,Y,W,H, list_Character_Positions
    alphabetPrediction = ''
    count = 0
    #cv2.imwrite(baseDir + '/testDir/'+'GetTextImg0.jpg',lImage)
# =============================================================================
#     total_space = 0
#     number_Of_Character = 0
#     last_Point = -1
# 
# =============================================================================
    Word_Dilated_Image = Get_Dilated_Image(lImage,11)
    Word_Contours = Get_Countours(Word_Dilated_Image)
    Word_Contours = Sort_Countours(Word_Contours,"left-to-right")
# =============================================================================
#     path = r'/Users/vk250027/Documents/Bevmo/Images/Test/' + 'Dilated_'+  str(count)+'.png'
#     cv2.imwrite(path,Word_Dilated_Image)
#             
# =============================================================================
    last_Word_Contour_Index = 0
    Word_X, Word_Y, Word_W, Word_H = cv2.boundingRect(Word_Contours[last_Word_Contour_Index])
    last_Word_Contour_Max_X_Range = Word_X + Word_W
    # i.e X + W
            

    for k,cnt in enumerate(contours):
        x,y,w,h = cv2.boundingRect(cnt)
        give_Space = False
        #print (x,y,w,h)
        #img = Image[y:y+h , x:x+w]
        #cv2.imwrite(r'/Users/vk250027/Documents/Bevmo/Images/Input/FinalTest/c' + str(k)+'.jpg',img)
        # Reject if Contour is not of desired size (too small)
        if w > Width and h > Height :# and x > 0 and y > 0:
    
            ## Spacing based on word formation
            if x > last_Word_Contour_Max_X_Range:
                give_Space = True
                last_Word_Contour_Index = last_Word_Contour_Index + 1
                Word_X, Word_Y, Word_W, Word_H = cv2.boundingRect(Word_Contours[last_Word_Contour_Index])
                last_Word_Contour_Max_X_Range = Word_X + Word_W
                # i.e X + W
                
            if give_Space == True:
                alphabetPrediction = alphabetPrediction + " "
                list_Character_Positions.append((-1,-1,-1,-1," "))
            
            
            resize_image = getNewResizedImage(lImage[y:y+h, x:x+w] , 28)
            #resize_image = cv2.dilate(resize_image,np.ones((2,2),np.uint8),iterations=1)
            
# =============================================================================
            cpath = baseDir + '/testDir/' + str(count)+'.png'
            #cv2.imwrite(cpath,resize_image)
#             #resize_image = resize_image.flatten()
# =============================================================================
            count = count + 1          
            if checkFor == 'Letters':
                
                prob = model.predict_proba(resize_image.reshape(1,28,28,1)/255.0)[0]
                sort_alphabet_probability = -np.sort(-prob)
                #if sort_alphabet_probability[0] >= 0.05:
                temp_Index = int(model.predict_classes(resize_image.reshape(1,28,28,1)/255.0)[0])
                alphabetPrediction = alphabetPrediction + list({k for k,v in y_labels.items() if v == temp_Index})[0]
                #list_Character_Positions.append((x+X,y+Y,w,h,str(list({k for k,v in y_labels.items() if v == temp_Index})[0])))
                    
            else:
                temp_Index = int(model.predict_classes(resize_image.reshape(1,28,28,1)/255.0)[0])
                alphabet_probability = (model.predict_proba(resize_image.reshape(1,28,28,1)/255.0))
                sort_alphabet_probability = -np.sort(-alphabet_probability)
                #if sort_alphabet_probability[0,0] > 0.95:
                alphabetPrediction = alphabetPrediction + digitList[int(temp_Index)]
                #list_Character_Positions.append((x+X,y+Y,w,h,str(digitList[int(temp_Index)])))

    #list_Character_Positions.append((-1,-1,-1,-1," "))

    return checkFor, alphabetPrediction
print("Point 6")
#-------------------------------------------------------------------------------
# =============================================================================
# Execution 
# =============================================================================
#Getting Hog

#hog = HogDescriptor()

#getting all the images from the folder
""" imgPath = baseDir + '/Images/input_images/'

#initialising New DataFrame


photos = os.listdir(imgPath)

#filtering unwanted file which usually omes in mac '.DS_Store'
if '.DS_Store' in photos:
    photos.remove('.DS_Store')
    
for number, image in enumerate (photos): """


print("Point 7")

def process(imgaeFilePath):
    

        photos = os.listdir(imgaeFilePath)
        photos = [i for i in photos if 'DS_Store' not in i][0]
        characters = []
        df = pd.DataFrame()    
        #print('Processing {}, wait it may take a while ..!'.format(photos[number]))
        image = cv2.imread(imgaeFilePath+'/'+photos)
        
        #resize the image for specific Dimention:
        image1 = cv2.resize(image,(1360,1060),interpolation = cv2.INTER_AREA)
        #image1 = cv2.resize(np.array(qimg),(1355,1045),interpolation = cv2.INTER_AREA)
        
        
        image1 = Get_Processed_Image(image1)
        x,y,w,h = cv2.boundingRect(image1)
        image1 = image1[y:y+h-180, x+165:x+w]
        img_bckedUp = image1
        #cv2.imwrite(baseDir +'/testDir/' + 'croped.jpg', image)
        image_With_Lines = Get_Dilated_Image(image1, 50)
    
        #cv2.imwrite(baseDir +'/testDir/' + 'wholeDialted.jpg', image_With_Lines) 
        
        contours = Get_Countours(image_With_Lines)
        #cv2.imwrite(baseDir +'/testDir/' + 'afterCnt1.jpg', image_With_Lines) 
        contours = Sort_Countours(contours, "top-to-bottom")
        #cv2.imwrite(baseDir +'/testDir/' + 'afterSortingContours_Image.jpg', image_With_Lines) 
        print(len(contours))
        
        #Draw_Contours(cv2.imread(imgPath),contours)
        Predicted_Text = ''
        temp_Index = ''
        global list_Character_Positions
        X=Y=W=H=0
        count = 20
        list_Character_Positions = []
        
        fields = []
        counts = 0
        index = 0
        Predicted_Text = ''
        for iter, line_Area in enumerate(contours):
            #print('Iteration:- ', iter)
            #print('len of Contours:- ', len(contours))
            counts = counts + 1
            x,y,w,h = cv2.boundingRect(line_Area)
            X,Y,W,H = x,y,w,h
            line_Image = image1[y:y+h, x:x+w]
            #path = r'C:\Users\sachin\Desktop\Images\\' + str(counts)+'.png'
            
            line_Contours = Get_Countours(image1[y:y+h, x:x+w])
            line_Contours = Sort_Countours(line_Contours,"left-to-right")
            #Draw_Contours(line_Image,line_Contours)
            
            if iter not in  range(len(contours)-3, len(contours)+1) :
                model = CharModel
                checkFor = 'Letters'
                Width,Height = 8,10
                
                
            else:
                model = digitModel
                checkFor = 'Digits'
                Width,Height = 2,8
            
            #cv2.imwrite(baseDir +'/testDir/' + 'BeforeGetTextImage0.jpg', img_bckedUp[y:y+h, x:x+w])
            
            retCheck, text = Get_Text_From_Image(img_bckedUp[y:y+h, x:x+w], line_Contours, model, checkFor, Width,Height)
            #print (text)
            if retCheck == 'Letters':
                text_new = text.lower()
                text_new = text_new.strip()
                #print ('Predicted text is: ', text_new)
                
                #if iter == 1 or iter == :
                # =============================================================================
                # #Extra Works           
                # =============================================================================
                if (('S T A T E' not in text_new and 's t a t e' not in text_new) and iter == 0): #or(('S T A T E' not in text_new and 's t a t e' not in text_new) and iter in range(len(contours)-4, len(contours)-3)):
                    
                    text = str(text_new).split(' ')
                    #print('simple text:',text)
                    if len(text)>1 :
                        characters.append(text[0].capitalize() + '\n')
                        characters.append( (''.join(text[2:])).capitalize() + '\n')
                    else:
                        characters.append(text[0].capitalize() + '\n')
                
                elif 'S T A T E' in text_new or 's t a t e' in text_new or iter in range(len(contours)-4, len(contours)-3):
                    #print('State text:',text_new)
                    if 'S T A T E' in text_new or 's t a t e' in text_new:
                        text = str(text_new).split('s t a t e')
                        text = [t.strip() for t in text]
                        characters.append(text[0].capitalize()+ '\n')
                        characters.append(text[-1].capitalize()+ '\n')
                    else:
                        text = str(text_new).split(' ')
                        if len(text) > 2:
                            text = [t.strip() for t in text]
                            characters.append(text[0].capitalize())
                            text = ''.join(text)[-2:] #getting the State Code
                            characters.append(text.capitalize()+ '\n')
                            #characters.append( (''.join(text[2:])).capitalize())
                        else:
                            text = [t.strip() for t in text]
                            characters.append(text[-1].capitalize() + '\n')
                            
                            
                            
                elif 'S T A T E' not in text_new and 's t a t e' not in text_new:
                    characters.append(text_new.capitalize() + '\n')
                
                        
            else:  # for Digits 
                text_new = text.strip()
                
                #checking the last contour of DOB field
                if iter == len(contours)-1:
                    text_new = text_new.split(' ')
                    text_new = ''.join(text_new)
                
                    #print('entered in DOB section')
                    text_new = text_new.replace(' ','')[0:6] #extracting 1st 6 digit corressponding to DOB field
                    text_new = text_new[0:2] + '-' + text_new[2:4] + '-' + text_new[4:]
                    characters.append(text_new.capitalize() + '\n')
                elif iter == len(contours)-2: # for mobile field as the size of box is very small so it might accept brackets as 1 so andling that here below:
                    #print(text_new)
                    text_new = text_new.split(' ')
                    #print('Mobile Text: ',text_new[0])
                    if len(text_new[0]) > 4:
                        #print('extracted Text: ',text_new[0][1:-1] )
                        characters.append(text_new[0][1:-1] + ''.join(text_new[1:]))
                    else:
                        characters.append(text_new[0][:-1] + ''.join(text_new[1:]))
                        
                else:
                    characters.append(text_new.capitalize())
     
         #removinfg any extra spaces
        for i in range(characters.count('')):
            characters.remove(str(''))
       
        #adding returning varibale 
        Text = characters
    # =============================================================================
    #     
    #     #creating Dataframe 
    #     Data = pd.DataFrame(characters)
    #     Data = Data.transpose()
    #     #Data.apply(str.lower)
    #     #Data.columns = ['First Name','Middle','Last Name', 'Email','Street', 'City', 'State','ZIP code','Phone','Birthdate',
    #                    #'Gender', 'Barcode','x']
    #     #Data = Data.apply(lambda x : x.astype(str).str.upper())
    #      
    #     #Apending the DATAFRAMES
    #     df = pd.concat([df,Data],axis=0,ignore_index=True)
    #     Data = pd.DataFrame()
    #     characters = []
    #     
    #     #print('Done with {}'.format(photos[number]))
    #     
    #     df.columns = ['First Name','Middle','Last Name', 'Email','Street', 'City', 'State','ZIP code','Phone','Birthdate']   
    # 
    #     df['State'] = df['State'].apply( lambda x : x.upper())
    #     df['State'] = df['State'].apply( lambda x : ''.join(x.split(' ')))
    #     df['City'] = df['City'].apply( lambda x : x.upper())
    #     df['Email'] = df['Email'].apply(lambda x : ''.join(str(x).split(' ') ) )
    #     # =============================================================================
    #     # # Writing file to Output directory
    #     # =============================================================================
    #     resultPath = baseDir + '/Results/'
    #     writer = pd.ExcelWriter(resultPath + 'Results1.xlsx')
    #     df.to_excel(writer,'Sheet1')
    #     writer.save()
    # 
    #     print('Done with Proccessing...!.Output is available at "{}" with file Name : Results1.xlsx'.format(resultPath))
    # =============================================================================
    #----------------------------------------------------------------------------------
        return(Text)

print("Point 8")


#process("/Volumes/Macintosh HD/Documents/Teradata/R Shiny/Bevmo_Demo/Images/samplev6/")



