import itertools
from typing import Optional

import MeCab
import pandas as pd


_TAGGER = MeCab.Tagger("-Ochasen")


def mecab_parse_texts(
    target_texts: pd.core.series.Series,
    ids: Optional[pd.core.series.Series] = None
) -> pd.core.frame.DataFrame:
    if ids:
        assert len(target_texts) == len(ids)
    parsed_texts = (
        target_texts
        .apply(_TAGGER.parse)
        .str.split('\n')
        .apply(lambda l: l[:-2])
        .tolist()
    )
    parsed_texts_series = pd.Series(list(itertools.chain.from_iterable(parsed_texts)))
    n_words = list(map(len, parsed_texts))
    positions = pd.Series(list(itertools.chain.from_iterable(map(range, n_words))))
    target_texts_column = pd.Series(
        list(
            itertools.chain.from_iterable(
                itertools.starmap(
                    itertools.repeat,
                    zip(target_texts, n_words)))))
    df_parse = pd.concat(
        [target_texts_column, positions, parsed_texts_series.str.split('\t', expand=True)],
        axis=1)
    df_parse.columns = [
        'original_text',
        'word_position',
        'surface_form',
        'pronunciation',
        'base_form',
        'word_class',
        'inflection_type',
        'inflection_form',
    ]
    if ids:
        id_column = pd.Series(
            list(
                itertools.chain.from_iterable(
                    itertools.starmap(
                        itertools.repeat,
                        zip(ids, n_words)))))
        df_parse = pd.concat([id_column.rename('id'), df_parse]).set_index('id')
    return df_parse
