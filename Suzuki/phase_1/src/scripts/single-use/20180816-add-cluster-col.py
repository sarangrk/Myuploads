'''クラスタリング結果の確認用スクリプト'''
import inspect
import pathlib

import pandas as pd
import pickle as pkl


PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent.parent

n_cluster = 8

doc_vector_path = str(
    PRJ_ROOT /
    'data' /
    'interim' /
    'FTIR_base_info_JP_4wheels_col_F_ID-F_FAULT_PROPOSAL_LL_0.4_s0-rep_hyph_parsed_doc_word_freq' /
    'alpha=0.6_beta=0.01_burn_in_iterations=900_num_topics=30_total_iterations=2000_plda-doc_topics.csv'
)
clusters_path = str(
    PRJ_ROOT /
    'reports' /
    'clusters_for_elbow_plot_30topics.pkl'
)
out_path = str(
    PRJ_ROOT / 'reports' / f'clusters-30topics-{n_clusters}clusters.csv'
)

# データ読み込み

df = pd.read_csv(doc_vector_path, encoding='utf-16', sep='\t')

with open(clusters_path, 'rb') as ifs:
    clusters = pkl.load(ifs)


for _n_cluster, _kmeans, _ in zip(*clusters):
    if _n_cluster == n_cluster:
        kmeans = _kmeans
        break

df_cluster_labeled = df.assign(cluster_id=kmeans.labels_)

df_sampled_within_clusters = df_cluster_labeled.groupby('cluster_id').apply(lambda df: df.sample(100, random_state=0))

df_sampled_within_clusters.to_csv(out_path, encoding='utf-16', sep='\t')

