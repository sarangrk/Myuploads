import cv2
import numpy as np
import time
import math
import os


#inputfilename = '/home/kaptan/hand_gesture/Hand_gesture_2.mp4'
#outputfilename = "/home/kaptan/hand_gesture/gesture_output_rev.mp4"

def Hand_Gesture(inputfilename, outputfilename):

	# Open video fil
	video = cv2.VideoCapture(inputfilename)
	print(video)
	def nothing(x):
		pass
	# Function to find angle between two vectors
	def Angle(v1,v2):
		dot = np.dot(v1,v2)
		x_modulus = np.sqrt((v1*v1).sum())
		y_modulus = np.sqrt((v2*v2).sum())
		cos_angle = dot / x_modulus / y_modulus
		angle = np.degrees(np.arccos(cos_angle))
		return angle
	# Function to find distance between two points in a list of lists
	def FindDistance(A,B):
		return np.sqrt(np.power((A[0][0]-B[0][0]),2) + np.power((A[0][1]-B[0][1]),2))
	# Starting with 100's to prevent error while masking
	h,s,v = 100,100,100
	width = video.get(cv2.CAP_PROP_FRAME_WIDTH)
	height = video.get(cv2.CAP_PROP_FRAME_HEIGHT)
	print(width,height)
	fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')
	out = cv2.VideoWriter(outputfilename,fourcc, 10.0, (int(width),int(height)))
	while(1):
		print(out)
		print("i am here")
		#Measure execution time
		start_time = time.time()
		#Capture frames from the camera
		ret, frame = video.read()
		if ret==True:
			frame=cv2.flip(frame,0)
		else:
		  break
		frame = cv2.resize(frame, (1200, 670), interpolation = cv2.INTER_LINEAR)
		try:
			#Blur the imageout.write
			blur = cv2.blur(frame,(3,3))
		except Exception as e:
			continue
		#Convert to HSV color space
		hsv = cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)
		#Create a binary image with where white will be skin colors and rest is black
		mask2 = cv2.inRange(hsv,np.array([2,50,50]),np.array([15,255,255]))
		#Kernel matrices for morphological transformation
		kernel_square = np.ones((11,11),np.uint8)
		kernel_ellipse= cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(5,5))
		dilation = cv2.dilate(mask2,kernel_ellipse,iterations = 1)
		erosion = cv2.erode(dilation,kernel_square,iterations = 1)
		dilation2 = cv2.dilate(erosion,kernel_ellipse,iterations = 1)
		filtered = cv2.medianBlur(dilation2,5)
		kernel_ellipse= cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(8,8))
		dilation2 = cv2.dilate(filtered,kernel_ellipse,iterations = 1)
		kernel_ellipse= cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(5,5))
		dilation3 = cv2.dilate(filtered,kernel_ellipse,iterations = 1)
		median = cv2.medianBlur(dilation2,5)
		ret,thresh = cv2.threshold(median,127,255,0)
		_,contours, hierarchy = cv2.findContours(thresh,cv2.RETR_TREE,cv2.CHAIN_APPROX_SIMPLE)

		#Find Max contour area (Assume that hand is in the frame)
		max_area=600
		ci=0
		for i in range(len(contours)):
			cnt=contours[i]
			area = cv2.contourArea(cnt)
			if(area>max_area):
				max_area=area
				ci=i
		#Largest area contour
		cnts = contours[ci]
		#Find convex hull
		try:
		  hull = cv2.convexHull(cnts)
		  hull2 = cv2.convexHull(cnts,returnPoints = False)
		  defects = cv2.convexityDefects(cnts,hull2)
		except:
		  continue
		  
		#Find convex defects
		
		#Get defect points and draw them in the original image
		FarDefect = []
		for i in range(defects.shape[0]):
			s,e,f,d = defects[i,0]
			start = tuple(cnts[s][0])
			end = tuple(cnts[e][0])
			far = tuple(cnts[f][0])
			FarDefect.append(far)
			cv2.line(frame,start,end,[0,255,0],1)
			cv2.circle(frame,far,10,[100,255,255],3)
		#Find moments of the largest contour
		moments = cv2.moments(cnts)
		#Central mass of first order moments
		if moments['m00']!=0:
			cx = int(moments['m10']/moments['m00']) # cx = M10/M00
			cy = int(moments['m01']/moments['m00']) # cy = M01/M00
		centerMass=(cx,cy)
		print(cx,cy)

		#Draw center mass
		cv2.circle(frame,centerMass,7,[100,0,255],2)
		font = cv2.FONT_HERSHEY_SIMPLEX
		cv2.putText(frame,'Center',tuple(centerMass),font,2,(255,255,255),2)
		#Distance from each finger defect(finger webbing) to the center mass
		distanceBetweenDefectsToCenter = []
		for i in range(0,len(FarDefect)):
			x =  np.array(FarDefect[i])
			centerMass = np.array(centerMass)
			distance = np.sqrt(np.power(x[0]-centerMass[0],2)+np.power(x[1]-centerMass[1],2))
			distanceBetweenDefectsToCenter.append(distance)
		#Get an average of three shortest distances from finger webbing to center mass
		sortedDefectsDistances = sorted(distanceBetweenDefectsToCenter)
		AverageDefectDistance = np.mean(sortedDefectsDistances[0:2])
		#Get fingertip points from contour hull
		#If points are in proximity of 80 pixels, consider as a single point in the group
		finger = []
		for i in range(0,len(hull)-1):
			if (np.absolute(hull[i][0][0] - hull[i+1][0][0]) > 110) or ( np.absolute(hull[i][0][1] - hull[i+1][0][1]) > 80):
				if hull[i][0][1] <500 :
					finger.append(hull[i][0])
		#The fingertip points are 5 hull points with largest y coordinates
		finger =  sorted(finger,key=lambda x: x[1])
		fingers = finger[0:5]
		#Calculate distance of each finger tip to the center mass
		fingerDistance = []
		for i in range(0,len(fingers)):
			distance = np.sqrt(np.power(fingers[i][0]-centerMass[0],2)+np.power(fingers[i][1]-centerMass[0],2))
			fingerDistance.append(distance)
		#Finger is pointed/raised if the distance of between fingertip to the center mass is larger
		#than the distance of average finger webbing to center mass by 130 pixels
		result = 0
		for i in range(0,len(fingers)):
			if fingerDistance[i] > AverageDefectDistance+130:
				result = result +1
		#Print number of pointed fingers
		cv2.putText(frame,str(result),(100,100),font,2,(255,255,255),2)
		#Print bounding rectangle
		x,y,w,h = cv2.boundingRect(cnts)
		img = cv2.rectangle(frame,(x,y),(x+w,y+h),(0,255,0),2)
		cv2.drawContours(frame,[hull],-1,(255,255,255),2)
		print("i am here1 ")
		##### Show final image ########
		# cv2.imshow('Dilation',frame)
		frame1=cv2.resize(frame, (640, 352), interpolation = cv2.INTER_LINEAR)
		# cv2.imshow('Resized Frame',frame1)
		out.write(frame1)
											 							 	 

	video.release()
#Hand_Gesture(inputfilename, outputfilename)


