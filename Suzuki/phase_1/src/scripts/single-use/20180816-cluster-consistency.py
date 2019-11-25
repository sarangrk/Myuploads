
import numpy as np
import pandas as pd
import pickle as pkl
import matplotlib.pyplot as plt

from sklearn.cluster import KMeans
from sklearn.feature_selection import f_classif
from sklearn.metrics import adjusted_rand_score


path = (
    '../data/interim/'
    'FTIR_base_info_JP_4wheels_col_F_ID-F_FAULT_PROPOSAL_LL_0.4_s0-rep_hyph_parsed_doc_word_freq/'
    'alpha=0.6_beta=0.01_burn_in_iterations=900_num_topics=30_total_iterations=2000_plda-doc_topics.csv'
)
df = pd.read_csv(path, encoding='utf-16', sep='\t')

X = np.sqrt(df.filter(regex=r'topic_[0-9]+', axis=1).values)

n_clusters = 16

seeds = [0, 1, 2, 3, 4]


clusters = []
scores = []
for seed in seeds:
    cluster = KMeans(
        n_clusters=n_clusters,
        max_iter=10000,
        random_state=seed,
    )
    cluster.fit(X)
    clusters.append(cluster)
    scores.append(cluster.inertia_)


RI_matrix = np.zeros((5,5))

for i in range(5):
    for j in range(5):
        RI_matrix[i, j] = adjusted_rand_score(
            clusters[i].labels_,
            clusters[j].labels_
        )

np.savetxt(f'RI_matrix{n_clusters}.csv', RI_matrix, delimiter='\t')
