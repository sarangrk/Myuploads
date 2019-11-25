#Import packages
import boto3
import botocore
import paramiko
from subprocess import call
import shutil
import os
from distutils.dir_util import copy_tree
import glob
import numpy as np

##reading the pathlocation.txt
def integration(pred_ind, state):
    ##reading remote detail from text and storing it in dictionary
    remote_detail = open('remote_detail.txt')
    remote_detail_list = [i.split(':') for i in remote_detail.read().splitlines()]
    empty_list = list()
    remote_detail_dict = list()
    for elem in remote_detail_list:
        empty_list = list()
        for each in elem:
            empty_list.append(each.strip())
        remote_detail_dict.append(empty_list)
    remote_detail_dict = dict(remote_detail_dict)

    if(state =='Train' or (state == 'Retrain' and pred_ind == False)):

        with open('pathlocation.txt') as f:
            from_dir_lines = f.readlines()
        f.close()
        open("pathlocation.txt", "w").close() ##clearing the .txt file

        from_dir_list=[]
        path_list = ['TrainImageDirectory','TestImageDirectory','ValidateImageDirectory','AnnotatedCSV']
        for i in range(4):
            for each_line in from_dir_lines:
                if(each_line.split('=')[0]==path_list[i]):
                    from_dir_list.append(each_line.split('=')[1][:-1])

        ##copy the folders from user specified path to the local Auto_label folders
        if not os.path.exists('./Data'):
            os.makedirs('./Data')

        ind = 0
        for i in from_dir_list:
            dst_dir = './Data/'+path_list[ind]
            if(os.path.isdir(dst_dir)):     ##before copying clearing already exisiting folder
                shutil.rmtree(dst_dir)
            os.mkdir(dst_dir)
            copy_tree(i,dst_dir)
            ind = ind +1
        shutil.rmtree('./Data/PredImageDirectory')
        os.mkdir('./Data/PredImageDirectory')

        ## copy the data from local auto label folder to aws if the train button is pressed or if retrain button is pressed along
        ## with pred indicator as False
        from_local_auto = ['./Data/TrainImageDirectory/','./Data/TestImageDirectory/','./Data/ValidateImageDirectory/','./Data/AnnotatedCSV/']
        to_aws_auto = ['Detection','Test_image','Val_image','annotated_xml']
        for i in range(4):
            #os.system('rsync -av --delete-after -e "ssh -i /Users/sk250120/Desktop/GDCAIPlatform.pem" '+ from_local_auto[i]+' ec2-user@13.59.97.192:/home/smitha/auto_label_aws_integration/keras_yolo3_master_final_1/EMTD/'+to_aws_auto[i]+'/')
            os.system('rsync -av --delete-after -e "ssh -i '+remote_detail_dict['Pemfile_path']+'" '+from_local_auto[i]+' '+remote_detail_dict['Username']+'@'+remote_detail_dict['Hostname']+':'+remote_detail_dict['Remote_location']+'EMTD/'+to_aws_auto[i]+'/')
    elif(state == 'Retrain' and pred_ind == True):

        ##moving the image from local auto pred folder to loal auto train, on which prediction was performed
        test_image_list = [i for i in os.listdir('./Data/TestImageDirectory/')]
        if('.DS_Store' in test_image_list):
            test_image_list.remove('.DS_Store') ##code to remove .DS_Store file for mac
        name_ext_dict = dict([i.split('.') for i in test_image_list])

        uniq_img_ext = tuple(set(name_ext_dict.values()))

        for i in os.listdir('./Data/PredImageDirectory/'):
            if(i.endswith(uniq_img_ext)):
                shutil.move('./Data/PredImageDirectory/'+i,'./Data/TrainImageDirectory/')

        #copying the xml from local pred folder to aws annotatedxml folder
        #os.system('rsync -ave "ssh -i /Users/sk250120/Desktop/GDCAIPlatform.pem" ./Data/PredImageDirectory/ ec2-user@13.59.97.192:/home/smitha/auto_label_aws_integration/keras_yolo3_master_final_1/EMTD/annotated_xml/')
        os.system('rsync -ave "ssh -i '+remote_detail_dict['Pemfile_path']+'" ./Data/PredImageDirectory/ '+ remote_detail_dict['Username']+'@'+remote_detail_dict['Hostname']+':'+remote_detail_dict['Remote_location']+'EMTD/annotated_xml/')
        shutil.rmtree('./Data/PredImageDirectory')
        os.mkdir('./Data/PredImageDirectory')

## when predcition code run , it will return true and then following should be executed
def integration_pred():
    ##reading remote detail from text and storing it in dictionary
    remote_detail = open('remote_detail.txt')
    remote_detail_list = [i.split(':') for i in remote_detail.read().splitlines()]
    empty_list = list()
    remote_detail_dict = list()
    for elem in remote_detail_list:
        empty_list = list()
        for each in elem:
            empty_list.append(each.strip())
        remote_detail_dict.append(empty_list)
    remote_detail_dict = dict(remote_detail_dict)

    #creating pred image folder in local auto folder if doesnt exist
    if(not os.path.exists('./Data/PredImageDirectory')):
        os.makedirs('./Data/PredImageDirectory')

    ## copying the xmls from aws to local auto folder pred_image folder
    #changepath
    #os.system('rsync -av --delete-after -e "ssh -i /Users/sk250120/Desktop/GDCAIPlatform.pem" ec2-user@13.59.97.192:/home/smitha/auto_label_aws_integration/keras_yolo3_master_final_1/EMTD/pred_image/ ./Data/PredImageDirectory/')
    os.system('rsync -av --delete-after -e "ssh -i '+remote_detail_dict['Pemfile_path']+'" '+remote_detail_dict['Username']+'@'+remote_detail_dict['Hostname']+':'+remote_detail_dict['Remote_location']+'EMTD/pred_image/ ./Data/PredImageDirectory/')

    ## moving images from local auto test folder to local pred_imaage folder
    pred_img_list = [i.split('.')[0]  for i in os.listdir('./Data/PredImageDirectory/') ]
    test_image_list = [i for i in os.listdir('./Data/TestImageDirectory/')]
    if('' in pred_img_list ):
        pred_img_list.remove('') ##code to remove .DS_Store file for mac
    if('.DS_Store' in test_image_list):
        test_image_list.remove('.DS_Store') ##code to remove .DS_Store file for mac
    name_ext_dict = dict([i.split('.') for i in test_image_list])

    for i in pred_img_list :
        shutil.move('./Data/TestImageDirectory/'+i+'.'+name_ext_dict[i],'./Data/PredImageDirectory/')
