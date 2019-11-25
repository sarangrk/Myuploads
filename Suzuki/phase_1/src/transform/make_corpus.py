import pandas as pd
from gensim.corpora.dictionary import Dictionary


def make_corpora_from_dataframe(
    df: pd.core.frame.DataFrame,
    key: str,
    word_col: str,
):
    word_lists = df.groupby(key)[word_col].apply(list).tolist()
    dictionary = Dictionary(word_lists)
    corpora = list(map(dictionary.doc2bow, word_lists))
    return dictionary, corpora
