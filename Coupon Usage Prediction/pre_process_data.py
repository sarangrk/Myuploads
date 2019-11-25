
import datetime
import json
import os
import time

import numpy as np

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
get_ipython().run_line_magic('matplotlib', 'inline')

import pandas as pd
import scipy.sparse

import seaborn as sns
sns.set(context="paper", font_scale=1.5, rc={"lines.linewidth": 2}, font='DejaVu Serif')

import pickle

DATA_DIR = r'C:\Users\KT250034\PROJECTS\CVS\new\new_data'

with open(DATA_DIR + r'\new_dataset\cofactor_dataframe\cofactor_dataframe_4_4.pkl', 'rb') as f:
    raw_data = pickle.load(f)

raw_data.head()


from teradataml.context.context import *
from teradataml.dataframe.dataframe import DataFrame
from teradataml import *


con = create_context(host = "tdap790t1.labs.teradata.com", username="GDCDS", password = "GDCDS")

copy_to_sql(raw_data, "CV_CofactorData")
