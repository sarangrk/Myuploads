#' # 類似文書クラスタリングのエルボープロット


#' ## 背景

#' 類似文書のクラスタごとに部品の分布を出したい。
#' まずはクラスタリングをする必要があるが、
#' 計算時間的に K-Means 法が妥当であると考えられる。
#' K-Means 法ではクラスタ数を決める必要があるので、
#' クラスタ数を決めるために Elbow Plot を作成することにした。

#' ## モジュールのロード

import numpy as np
import pandas as pd
import pickle as pkl
import matplotlib.pyplot as plt

from sklearn.cluster import KMeans
from sklearn.feature_selection import f_classif

#' ## データ読み込み

path = (
    '../data/interim/'
    'FTIR_base_info_JP_4wheels_col_F_ID-F_FAULT_PROPOSAL_LL_0.4_s0-rep_hyph_parsed_doc_word_freq/'
    'alpha=0.6_beta=0.01_burn_in_iterations=900_num_topics=30_total_iterations=2000_plda-doc_topics.csv'
)
df = pd.read_csv(path, encoding='utf-16', sep='\t')

X = np.sqrt(df.filter(regex=r'topic_[0-9]+', axis=1).values)


#' ## クラスタリング

clusters = []
scores = []
ks = list(range(3, 20)) + [25, 30, 40, 45, 50]
for i in ks:
    cluster = KMeans(n_clusters=i, max_iter=10000, random_state=0)
    cluster.fit(X)
    clusters.append(cluster)
    scores.append(cluster.inertia_)

#' 保存'

with open('clusters_for_elbow_plot_30topics.pkl', 'wb') as ofs:
    pkl.dump((ks, clusters, scores), ofs)

#' エルボープロット

plt.plot(ks, scores)
plt.grid()
plt.savefig('elbow_plot_30topics.png')

