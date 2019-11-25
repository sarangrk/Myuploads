#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri May 24 16:10:45 2019

@author: hr250012
"""

import itertools
import glob
import os
import sys
os.environ['OPENBLAS_NUM_THREADS'] = '1'

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd
from scipy import sparse
import seaborn as sns
sns.set(context="paper", font_scale=1.5, rc={"lines.linewidth": 2}, font='DejaVu Serif')

import cofacto
import rec_eval

from teradataml import *

import datetime
import json

import time





Vantage = create_context(host = "tdap790t1.labs.teradata.com", username="GDCDS", password = "GDCDS")


from teradataml.dataframe.dataframe import DataFrame

from teradataml.dataframe.dataframe import in_schema


#data = DataFrame(in_schema("loblaws", "pos_training_new"))



df1 = DataFrame.from_table('loblaws.pos_training_new')

df1.info()

df1.columns

df = df1.to_pandas(index_column='customer_id')

df.reset_index(inplace=True)

df.columns


data = df[['customer_id','txn_date','product']]

data.columns=['UID','DATE','SID']


def date_to_timestamp(date):
    return time.mktime(datetime.datetime.strptime(date, "%d.%m.%Y").timetuple())



ts=data['DATE'].apply(lambda x: date_to_timestamp(x)).astype(int)

data['timestamp']=ts

data = data.sort_index(by=['timestamp'])


print("Time span of the dataset: From %s to %s" % 
      (np.min(data.DATE), np.max(data.DATE)))

len(data.timestamp)

data.columns




df2 = DataFrame.from_table('loblaws.pos_validation_new')

df2.info()

df2.columns

df2 = df2.to_pandas(index_column='customer_id')

df2.reset_index(inplace=True)

df2.columns


test_data = df2[['customer_id','txn_date','product']]

test_data.columns=['UID','DATE','SID']



ts=test_data['DATE'].apply(lambda x: date_to_timestamp(x)).astype(int)

test_data['timestamp']=ts

test_data = test_data.sort_index(by=['timestamp'])


print("Time span of the dataset: From %s to %s" % 
      (np.min(test_data.DATE), np.max(test_data.DATE)))

len(test_data.timestamp)





def get_count(tp, id):
    playcount_groupbyid = tp[[id]].groupby(id, as_index=False)
    count = playcount_groupbyid.size()
    return count

def filter_triplets(tp):
 
    usercount, itemcount = get_count(tp, 'UID'), get_count(tp, 'SID') 
    return tp, usercount, itemcount

data.columns
test_data.columns





total_raw_data, user_activity, item_popularity = filter_triplets(pd.concat([data,test_data],axis=0))


user_activity.hist(range=(0,2000))

item_popularity.hist(range=(0,2000))



sparsity = 1. * data.shape[0] / (user_activity.shape[0] * item_popularity.shape[0])

unique_uid = user_activity.index
unique_sid = item_popularity.index



segment2id = dict((sid, i) for (i, sid) in enumerate(unique_sid))
user2id = dict((uid, i) for (i, uid) in enumerate(unique_uid))



def numerize(tp):
    uid = list(map(lambda x: user2id[x], tp['UID']))
    sid = list(map(lambda x: segment2id[x], tp['SID']))
    tp['uid'] = uid
    tp['sid'] = sid
    return tp[['timestamp', 'uid', 'sid']]


train_data = numerize(data)
test_data = numerize(test_data)



n_items = len(unique_sid)
n_users = len(unique_uid)



print(n_users, n_items)

shape=(n_users, n_items)

from scipy import sparse



def load_data(df, shape=(n_users, n_items)):
    tp = df
    timestamps, rows, cols = np.array(tp['timestamp']), np.array(tp['uid']), np.array(tp['sid'])
    seq = np.concatenate((rows[:, None], cols[:, None], np.ones((rows.size, 1), dtype='int'), timestamps[:, None]), axis=1)
    data = sparse.csr_matrix((np.ones_like(rows), (rows, cols)), dtype=np.int16, shape=shape)
    return data, seq

train_data, train_raw = load_data(data)
test_data, test_raw = load_data(test_data)


train_data.A

test_data.A




plt.semilogx(1 + np.arange(n_users), -np.sort(-user_activity), 'o')
plt.ylabel('Number of items that this user baught in one transaction')
plt.xlabel('User rank by number of items bought')



plt.semilogx(1 + np.arange(n_items), -np.sort(-item_popularity), 'o')
plt.ylabel('Number of users who purchased this item')
plt.xlabel('Item rank by number of purchases')
pass


DATA_DIR = '/Documents/Teradata/Teradata_Vantage/LobLaws/Solution/code/cofactor'

def _coord_batch(lo, hi, train_data):
    rows = []
    cols = []
    for u in range(lo, hi):
        for w, c in itertools.permutations(train_data[u].nonzero()[1], 2):
            rows.append(w)
            cols.append(c)
    np.save(os.path.join(DATA_DIR, 'coo_%d_%d.npy' % (lo, hi)),
            np.concatenate([np.array(rows)[:, None], np.array(cols)[:, None]], axis=1))
    pass



from joblib import Parallel, delayed

batch_size = 5000

start_idx = range(0, n_users, batch_size)
end_idx = list(start_idx[1:]) + [n_users]

Parallel(n_jobs=8)(delayed(_coord_batch)(lo, hi, train_data) for lo, hi in zip(start_idx, end_idx))
pass



X = sparse.csr_matrix((n_items, n_items), dtype='float32')

for lo, hi in zip(start_idx, end_idx):
    coords = np.load(os.path.join(DATA_DIR, 'coo_%d_%d.npy' % (lo, hi)))
    
    rows = coords[:, 0]
    cols = coords[:, 1]
    
    tmp = sparse.coo_matrix((np.ones_like(rows), (rows, cols)), shape=(n_items, n_items), dtype='float32').tocsr()
    X = X + tmp
    
    print("User %d to %d finished" % (lo, hi))
    sys.stdout.flush()
    
    
1-float(X.nnz) / np.prod(X.shape)



n_pairs = X.data.sum()


M = X.copy()


def get_row(Y, i):
    lo, hi = Y.indptr[i], Y.indptr[i + 1]
    return lo, hi, Y.data[lo:hi], Y.indices[lo:hi]

count = np.asarray(X.sum(axis=1)).ravel()

for i in range(n_items):
    lo, hi, d, idx = get_row(M, i)
    M.data[lo:hi] = np.log(d * n_pairs / (count[i] * count[idx]))

M.A

M.data[M.data < 0] = 0
M.eliminate_zeros()


M.A

1-float(M.nnz) / np.prod(M.shape)




# number of negative samples
k_ns = 1

M_ns = M.copy()

offset = 0.


# not needed for offset = 0    
M_ns.data -= offset
M_ns.data[M_ns.data < 0] = 0
M_ns.eliminate_zeros()

M_ns.A


plt.hist(M_ns.data, bins=200)
plt.yscale('log')
pass



## Model Training


scale = 0.03

n_components = 100
max_iter = 20
n_jobs = 8
lam_theta = lam_beta = 1e-5 * scale
lam_gamma = 1e-5
c0 = 1. * scale
c1 = 10. * scale

save_dir = os.path.join(DATA_DIR, 'ML20M_ns%d_scale%1.2E' % (k_ns, scale))

import cofacto

coder = cofacto.CoFacto(n_components=n_components, max_iter=max_iter, batch_size=1000, init_std=0.01, n_jobs=n_jobs, 
                        random_state=98765, save_params=True, save_dir=save_dir, early_stopping=True, verbose=True, 
                        lam_theta=lam_theta, lam_beta=lam_beta, lam_gamma=lam_gamma, c0=c0, c1=c1)
        


coder.fit(train_data, M_ns, vad_data=test_data, batch_users=5000, k=100)




n_params = len(glob.glob(os.path.join(save_dir, '*.npz')))

params = np.load(os.path.join(save_dir, 'CoFacto_K%d_iter%d.npz' % (n_components, n_params - 1)))
U, V = params['U'], params['V']



U.shape

V.shape

R=U.dot(V.T)

R


from sklearn.preprocessing import MinMaxScaler 




#------------------------------
# CREATE USER RECOMMENDATIONS
#------------------------------
def recommend(original_user_id, data_sparse, user_vecs, item_vecs, user2id, seg2id, id2user, id2seg, num_items=10):
    """Recommend items for a given user given a trained model

    Args:
    user_id (int): The id of the user we want to create recommendations for.

    data_sparse (csr_matrix): Our original training data.

    user_vecs (csr_matrix): The trained user x features vectors

    item_vecs (csr_matrix): The trained item x features vectors

    id2seg (dictionary): Used to map ids to segment names

    num_items (int): How many recommendations we want to return:

    Returns:
    recommendations (pandas.DataFrame): DataFrame with num_items artist names and scores

    """
    user_id = user2id[original_user_id]
    # Get all interactions by the user
    user_interactions = data_sparse[user_id,:].toarray()
 
    # We don't want to recommend items the user has consumed. So let's
    # set them all to 0 and the unknowns to 1.
    user_interactions = user_interactions.reshape(-1) + 1 #Reshape to turn into 1D array
    user_interactions[user_interactions > 1] = 0
 
    # This is where we calculate the recommendation by taking the
    # dot-product of the user vectors with the item vectors.
    rec_vector = user_vecs[user_id,:].dot(item_vecs.T)
 
    # Let's scale our scores between 0 and 1 to make it all easier to interpret.
    min_max = MinMaxScaler()
    rec_vector_scaled = min_max.fit_transform(rec_vector.reshape(-1,1))[:,0]
    recommend_vector = rec_vector_scaled
 
    # Get all the segments indices in order of recommendations (descending) and
    # select only the top "num_items" items.
    item_idx = np.argsort(recommend_vector)[::-1][:num_items]
 
    top_n_recommended_items = []
    item_scores = []
 
    # Loop through our recommended segments indicies and look up the actial artist name
    top_n_recommended_items = list(map(lambda x: id2seg[x], item_idx))
    top_n_recommended_items
 

    for item_id in item_idx:
        item_scores.append(recommend_vector[item_id])
 
    # Create a new dataframe with recommended artist names and scores
    recommendations = pd.DataFrame({'items': top_n_recommended_items, 'score': item_scores})
 
    return recommendations.sort_values(['score'], ascending=[False])


seg2id = dict((sid, i) for (i, sid) in enumerate(unique_sid)) 
user2id = dict((uid, i) for (i, uid) in enumerate(unique_uid))


id2seg = dict((i, sid) for (i, sid) in enumerate(unique_sid))
id2user = dict((i, uid) for (i, uid) in enumerate(unique_uid))


recommendations={}

for i in range(n_users):
    recommendations[id2user[i]] = recommend(id2user[i],train_data,U,V,user2id,seg2id,id2user,id2seg,10)


recommendations
