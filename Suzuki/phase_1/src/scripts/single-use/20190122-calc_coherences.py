from functools import partial
from itertools import product, starmap
from logging import INFO, StreamHandler, getLogger
from multiprocessing import Pool
from os import path

import pickle

import numpy as np
import pandas as pd
from gensim import corpora
from gensim.models import HdpModel, LdaModel
from gensim.models.coherencemodel import CoherenceModel

logger = getLogger(__name__)
logger.setLevel(INFO)
logger.addHandler(StreamHandler())

PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)
DATA_PATH = path.join(PRJ_ROOT, 'data')

file_name = path.join(DATA_PATH, "data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen_noise_parts_count.csv")
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
        passes=150,
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
    df_parsed = pd.read_csv(file_name, sep='\t', encoding='utf-16')
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

    with open('result_.pkl', 'wb') as ofs:
        pickle.dump(results, ofs)
