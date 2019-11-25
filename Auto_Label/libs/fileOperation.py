import sys
import os
from pathlib import *

def write_to_file(name, content):
    #a=str(Path.home())
    #path = os.path.join(a, "pathlocation.txt")
    f= open("pathlocation.txt","a+")
    f.write(name+content+"\n")
    f.close()

def write_counter(content):
    #a=str(Path.home())
    #path = os.path.join(a, "retraincounter.txt")
    f=open("retraincounter.txt","w+")
    f.write(str(content))
    f.close()

def read_counter():
    #a=str(Path.home())
    #path = os.path.join(a, "retraincounter.txt")
    f=open("retraincounter.txt","r")
    if f.mode == "r":
        content=f.read()
        return int(content)

def check_value():
    #a=str(Path.home())
    #path = os.path.join(a, "pathlocation.txt")
    if 'TrainImageDirectory' in open("pathlocation.txt").read():
        if 'TestImageDirectory' in open("pathlocation.txt").read():
            if 'ValidateImageDirectory' in open("pathlocation.txt").read():
                if 'AnnotatedCSV' in open("pathlocation.txt").read():
                    return True

def removefile():
    #a=str(Path.home())
    #path = os.path.join(a, "pathlocation.txt")
    try:
        os.remove("pathlocation.txt")
    except OSError:
        pass

def file_exists():
    if os.path.exists("pathlocation.txt"):
        return True
