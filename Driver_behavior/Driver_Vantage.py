# -*- coding: utf-8 -*-
"""
Created on Mon Dec 10 12:30:35 2018

@author: pl186042
"""

import sys
import csv
import pickle
import pandas as pd
import keras
from keras.utils import to_categorical
import tensorflow as tf
import numpy as np
class Detect():
    def __init__(self):
       self.filename = 'C:/Users/PL186042/Music/Driver_behavior/model.pkl'
       self.loaded_model = pickle.load(open(self.filename, 'rb'))
       self.dictn = 'C:/Users/PL186042/Music/Driver_behavior/Final_code/Category.pkl'
       self.loaddict = pickle.load(open(self.dictn, 'rb'))
       self.compnycode = 'C:/Users/PL186042/Music/Driver_behavior/Final_code/lableEncodingforCompanyCode.pkl'
       self.loadcompnycode = pickle.load(open(self.compnycode, 'rb'))
       self.Fuel = 'C:/Users/PL186042/Music/Driver_behavior/Final_code/lableEncodingforFuelType.pkl'
       self.loadFuel = pickle.load(open(self.Fuel, 'rb'))
       self.vehicl = 'C:/Users/PL186042/Music/Driver_behavior/Final_code/lableEncodingforVehicle.pkl'
       self.loadvehicl = pickle.load(open(self.vehicl, 'rb'))
    
    def Load_data(self):
        self.csvname = 'C:/Users/PL186042/Music/Driver_behavior/Test.csv'
        self.loadcsv = pd.read_csv(self.csvname)
    
    def Preprocessing(self):
        #One hot encoding on Company code, Vehicle type description and fuel type based on label encoder.
        # step 1: Using Label encoder convert above three columns  to  numeric data
        # step 2: Using Keras convert it into binary form 
        # step 3 : Append it to data
        #self.loadcompnycode.
        #pass
        Company = self.loadcompnycode.transform(self.loadcsv['COMPANY_CODE'])
        Vehicle = self.loadvehicl.transform(self.loadcsv['VEHICLE_TYPE_DESCRIPTION'])
        Fuel = self.loadFuel.transform(self.loadcsv['FUEL_TYPE'])
        
        # NowConverting numerical values to one hot encoding
        Company_1 = to_categorical(Company, num_classes=len(self.loadcompnycode.classes_)-1)
        Vehicle_1= to_categorical(Vehicle, num_classes=len(self.loadvehicl.classes_)-1)
        Fuel_1 = to_categorical(Fuel, num_classes=len(self.loadFuel.classes_)-1)
   #'COMPANY_CODE'])
        # Deleting preprocessed columns 
        self.loadcsv.drop(['COMPANY_CODE','VEHICLE_TYPE_DESCRIPTION','FUEL_TYPE','PRODUCT_CODE' , 
                           'TM_REGISTRATION_NUMBER','TM_DRIVERID'],axis =1,inplace = True)
        
        z = np.column_stack((Company_1,Vehicle_1,Fuel_1))
        Df = pd.DataFrame(z)
        Final = pd.concat([self.loadcsv,Df],axis = 1)
        return Final
    
    def Predict(self,data):
        Pred = self.loaded_model.predict(data)
# =============================================================================
#         for item in pred:
#             print(self.loaddict[item])
# =============================================================================
        
        
        return [self.loaddict[item] for item in Pred]
        
        
        
#vehTypeLabelEncoder.fit(data_neww['VEHICLE_TYPE_DESCRIPTION'])
#fuelTypeLableEncoder.fit(data_neww['FUEL_TYPE' 
    #csvreader = csv.reader(sys.stdin, delimiter=',')
    
 #data_neww.drop(['PRODUCT_CODE' , 'TM_REGISTRATION_NUMBER','TM_DRIVERID'],axis =1)  
 
obj = Detect()

obj.Load_data()

Final_data = obj.Preprocessing()

output = obj.Predict(Final_data)