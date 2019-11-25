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

in_parsed_docs_path = path.join(DATA_PATH, "interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen_noise_parts_count.csv")
out_model_path = path.join(DATA_PATH, "interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen_noise_parts_count-stop_words=stop_words.1.csv_doc_word_freq/gensim_lm.model")
out_path = path.join(DATA_PATH, "interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen_noise_parts_count-stop_words=stop_words.1.csv_doc_word_freq/gensim_doc_topic.csv")
num_topics = 75
seed = 0


if __name__ == "__main__":
    df_parsed = pd.read_csv(file_name, sep='\t', encoding='utf-16')
    df_parsed = df_parsed.query('base_form != "する"')
    parsed_col = df_parsed[['id', 'base_form']].dropna().groupby('id').base_form.apply(list)
    np.random.seed(seed)
    dictionary = corpora.Dictionary(parsed_col)
    corpus = (
        parsed_col
        .apply(dictionary.doc2bow)
        # .to_frame('corpus')
        # .reset_index()
    )
    lm = LdaModel(
        corpus.tolist(),
        id2word=dictionary,
        alpha='auto',
        eta='auto',
        num_topics=num_topics,
        random_state=0,
        passes=150,
        gamma_threshold=1e-3,
        dtype=np.float64
    )
    lm.save(out_model_path)
    df_topics = pd.DataFrame.from_records(
        [dict(lm.get_document_topics(corpus))]
    ).assign(id=corpus.index)
    df_result = df_parsed[['id', 'doc']].drop_duplicates().merge(df_topics)
