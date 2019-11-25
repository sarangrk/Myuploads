import argparse
import inspect
import os.path as path
import pickle
import sys
from functools import partial
from itertools import product, starmap
from multiprocessing import Pool
from logging import INFO, StreamHandler, getLogger


import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from gensim import corpora
from gensim.models import HdpModel, LdaModel
from gensim.models.coherencemodel import CoherenceModel

logger = getLogger(__name__)
logger.setLevel(INFO)
logger.addHandler(StreamHandler())

PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)
DATA_PATH = path.join(PRJ_ROOT, 'data')
sys.path.append(path.join(PRJ_ROOT, 'src'))


n_topics = [10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 200]
n_folds = 5
seed = 0

def calc_folds(
    df_text_folds,
    dictionary,
    df_parsed,
    fold,
    num_topics,
):
    logger.info(f'{num_topics} topics {fold}th fold started.')
    train_corpus = df_text_folds.query('fold != @fold').corpus.tolist()
    # test_texts = df_text_folds.query('fold == @fold').text.tolist()
    df_parsed = df_parsed[['id', 'base_form']]
    df_parsed_folds = df_parsed.merge(df_text_folds[['id', 'fold']])
    df_train_vocab = df_parsed_folds.query('fold != @fold')[['base_form']].drop_duplicates()
    test_texts = df_parsed_folds.merge(df_train_vocab, on='base_form').groupby('id').base_form.apply(list).tolist()
    lm = LdaModel(
        train_corpus,
        id2word=dictionary,
        alpha='auto',
        eta='auto',
        num_topics=num_topics,
        random_state=0,
        passes=100,
        gamma_threshold=1e-3,
        dtype=np.float64
    )
    coherencemodel = CoherenceModel(
        model=lm,
        texts=test_texts,
        coherence='c_v',
        processes=1
    )
    logger.info(f'{num_topics} topics {fold}th fold end.')
    return num_topics, fold, lm, coherencemodel, coherencemodel.get_coherence()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('IN_FILE_PATH', help='入力ファイル(分かち書き結果の CSV)')
    parser.add_argument('OUT_FILE_PATH', help='出力先')
    parser.add_argument('OUT_PLOT_PATH', help='プロットの出力先')
    args = parser.parse_args()
    IN_FILE_PATH = args.IN_FILE_PATH
    OUT_FILE_PATH = args.OUT_FILE_PATH
    OUT_PLOT_PATH  = args.OUT_PLOT_PATH
    df_parsed = pd.read_csv(IN_FILE_PATH, sep='\t', encoding='utf-16')
    df_parsed = df_parsed.query('base_form != "する"')
    parsed_col = df_parsed[['id', 'base_form']].dropna().groupby('id').base_form.apply(list)
    np.random.seed(seed)
    folds = np.random.randint(0, n_folds, len(parsed_col))
    dictionary = corpora.Dictionary(parsed_col)
    df_text_folds = pd.DataFrame({'text': parsed_col, 'fold': folds, 'corpus': parsed_col.apply(dictionary.doc2bow)}).reset_index()

    curried = partial(
        calc_folds,
        df_text_folds,
        dictionary,
        df_parsed
    )
    with Pool(processes=7) as p:
        results = p.starmap(
            curried,
            list(product(range(n_folds), n_topics))
        )

    with open(OUT_FILE_PATH, 'wb') as ofs:
        pickle.dump(results, ofs)

    df_coherence = pd.DataFrame(results)
    df_coherence.columns = ['n_topic', 'fold', 'lda_model', 'coherence_model', 'coherence']
    sns.lineplot(data=df_coherence, err_style='bars', x='n_topic', y='coherence')
    plt.savefig(OUT_PLOT_PATH)
