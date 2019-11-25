import urllib
from urllib.request import urlopen
def wait_for_internet_connection():
    while True:
        try:
            response = urllib.request.urlopen('https://www.google.com/',timeout=1)
            return
        except urllib.error:
            pass

wait_for_internet_connection()


import requests
def check_internet():
    url='http://www.google.com/'
    timeout=5
    try:
        _ = requests.get(url, timeout=timeout)
        return True
    except requests.ConnectionError:
        print("connection drop.")
    return False



while True:
    connection = check_internet()
    if(connection == True):
        #copy the log.txt to local
        os.system('rsync -aveI "ssh -i '+remote_detail_dict['Pemfile_path']+'" '+remote_detail_dict['Username']+'@'+remote_detail_dict['Hostname']+':'+remote_detail_dict['Remote_location']+'training_log.txt ./logs/')
        #check if training is complete
        os.system('rsync -ave "ssh -i '+remote_detail_dict['Pemfile_path']+'" '+remote_detail_dict['Username']+'@'+remote_detail_dict['Hostname']+':'+remote_detail_dict['Remote_location']+'return_val.txt ./Data/')
        f = open('./Data/return_val.txt','r')
        content = f.read()
        if(content.split(':')[0]=='train_model_return_val'):
            if(int(content.split(':')[1])==1):
                break
        #waite for some time
        time.sleep(10*60)

    elif(connection == False):
        while !resume:
            #check resume
            if(resume == True):
                break
            time.sleep(60)
    elif(connection == False and resume ==True):
        while not connection:
            connection = check_internet()
            if(connection ):
                break
