import pickle
from os import path

import pandas as pd
import matplotlib.pyplot as plt
from pandas_profiling import ProfileReport

PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)

infile = path.join(PRJ_ROOT, 'data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen_noise_parts_count-stop_words=stop_words.1.csv_doc_word_freq/alpha=0.83_beta=0.01_burn_in_iterations=1800_compute_likelihood=true_likelihood_interval=-1_num_topics=60_progress_file=_random_seed=0_total_iterations=2000_plda-doc_topics.csv')
outfile = path.join(PRJ_ROOT, 'reports/60topics_topic_distribution.hml')
rf_file = path.join(PRJ_ROOT, 'data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen_noise_parts_count-stop_words=stop_words.1.csv_doc_word_freq/rf_60topics.1/rf50.pkl')
outdir = path.join(PRJ_ROOT, 'reports/topic_hist')

df_topics = pd.read_csv(infile, encoding='utf-16', delimiter='\t')

report = ProfileReport(df_topics)

report.to_file(outfile)

for i in range(60):
    plt.clf()
    s = df_topics[f'topic_{i}']
    s = s[(s.quantile(0.01) < s) & (s < s.quantile(0.99))]
    s.hist()
    # plt.savefig(f'{outdir}/topic_{i}.svg')
    plt.savefig(f'{outdir}/topic_{i}.png')

with open(rf_file, 'rb') as ifs:
    rf = pickle.load(ifs)

thresholdss = []
for i in range(60):
    thresholds = list()
    for estimator in rf.estimators_:
        tree = estimator.tree_
        thresholds.extend(tree.threshold[tree.feature == i].tolist())
    thresholdss.append(thresholds)

for i, thresholds in enumerate(thresholdss):
    plt.clf()
    plt.hist(thresholds)
    plt.savefig(f'{outdir}/splits_topic_{i}.png')
