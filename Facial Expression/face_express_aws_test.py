import numpy as np
import cv2
from keras.preprocessing import image
import os
#import tensorflow as tf
#-----------------------------

#sess = tf.Session(config=tf.ConfigProto(log_device_placement=True))

FILE_OUTPUT = (r'./DemoVideoOut/DemoFaceExpression.mp4')
def assure_path_exists(FILE_OUTPUT):
	dir = os.path.dirname(FILE_OUTPUT)
	if not os.path.exists(dir):
		os.makedirs(dir)


def performdetection(inputfilename, outputfilename):

  #opencv initialization

  face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

  cap = cv2.VideoCapture(inputfilename)

  width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
  height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)


  fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')
  out = cv2.VideoWriter(outputfilename,fourcc, 10.0, (int(width),int(height)))
  #
  #fourcc = cv2_VideoWriter_fourcc( 'm', 'p', '4', 'v')
  #out = cv2.VideoWriter(FILE_OUTPUT,fourcc,10.0,(int(height),int(width)))

  #-----------------------------
  #face expression recognizer initialization
  from keras.models import model_from_json
  model = model_from_json(open(r'./facial_expression_model_structure.json', "r").read())
  model.load_weights('./facial_expression_model_weights.h5') #load weights

  #-----------------------------

  emotions = ('angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral')

  frame = 0

  while(True):
  	ret, img = cap.read()

  	#if (ret == False):
  	  #break
  	#frame=cv2.flip(frame,1)

	gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

  	faces = face_cascade.detectMultiScale(gray, 1.3, 5)

  	#print(faces) #locations of detected faces

  	for (x,y,w,h) in faces:
		if w > 130:
			detected_face = frame[int(y):int(y+h), int(x):int(x+w)] #crop detected face
			detected_face = cv2.cvtColor(detected_face, cv2.COLOR_BGR2GRAY) #transform to gray scale
			detected_face = cv2.resize(detected_face, (48, 48)) #resize to 48x48
			img_pixels = image.img_to_array(detected_face)
			img_pixels = np.expand_dims(img_pixels, axis = 0)
			img_pixels /= 255 #pixels are in scale of [0, 255]. normalize all pixels in scale of [0, 1]
			predictions = model.predict(img_pixels) #store probabilities of 7 expressions
			#find max indexed array 0: angry, 1:disgust, 2:fear, 3:happy, 4:sad, 5:surprise, 6:neutral
			max_index = np.argmax(predictions[0])

			overlay = img.copy()
			opacity = 0.4
			cv2.rectangle(img,(x+w+10,y-25),(x+w+150,y+115),(64,64,64),cv2.FILLED)
			cv2.addWeighted(overlay, opacity, img, 1 - opacity, 0, img)

			cv2.line(img,(int((x+x+w)/2),y+15),(x+w,y-20),(255,255,255),1)
			cv2.line(img,(x+w,y-20),(x+w+10,y-20),(255,255,255),1)

			#emotion = emotions[max_index]
			emotion = ""
			for i in range(len(predictions[0])):
				motion = "%s %s%s" % (emotions[i], round(predictions[0][i]*100, 2), '%')
				color = (255,255,255)
				cv2.putText(img, emotion, (int(x+w+15), int(y-12+i*20)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)
				#-------------------------



			#write emotion text above rectangle
			cv2.putText(img, emotion, (int(x), int(y)), cv2.FONT_HERSHEY_SIMPLEX, 1, (255,255,255), 2)
			#process on detected face end
			#-------------------------
			#cv2.imshow('Frame',frame)
			out.write(img)
			#if cv2.waitKey(1) & 0xFF == ord('q'): #press q to quit
			#break

  #kill open cv things
  cap.release()
  #cv2.destroyAllWindows()
