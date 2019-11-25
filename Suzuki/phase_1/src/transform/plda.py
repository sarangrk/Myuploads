'''PLDA とのインターフェースになるモジュール

PLDA が入ったディレクトリ `plda` は `src` ディレクトリと
同じ階層に置くこと。
'''
import inspect
import pathlib
from contextlib import ExitStack
from subprocess import call
from tempfile import NamedTemporaryFile
from typing import Optional

import numpy as np
import pandas as pd

from utils.pandas import anti_join
from . import PRJ_ROOT


TRAIN_PATH = str(PRJ_ROOT / 'plda' / 'lda')
INFER_PATH = str(PRJ_ROOT / 'plda' / 'infer')


def shape_plda_input(df_parsed_docs, df_stop_words=None, n_minimum_words=1):
    df_nouns = df_parsed_docs[df_parsed_docs.used]
    # 未知語には base_form がないが未知語も使いたいので、base_form が存在しないものは
    # surface_form で埋める。
    df_nouns = df_nouns.assign(
        base_form=df_nouns.base_form.fillna(df_nouns.surface_form)
    )
    df_nouns_frequency = df_nouns.groupby('base_form').size().reset_index()
    df_nouns_frequency.columns = ['base_form', 'freq']
    df_nouns_frequency = df_nouns_frequency.assign(
        is_kept=(df_nouns_frequency.freq > n_minimum_words)
    )
    if df_stop_words is not None:
        df_nouns_frequency = df_nouns_frequency.pipe(
            anti_join,
            df_stop_words,
            left_on='base_form',
            right_on='word',
        )

    df_nouns = df_nouns.merge(
        df_nouns_frequency.query('is_kept'),
        how='inner',
        on=['base_form']
    )

    df_doc_word_freq = (
        df_nouns
        .groupby(['id', 'original_text', 'base_form'])
        .size()
        .reset_index()
    )
    df_doc_word_freq.columns = ['id', 'original_text', 'base_form', 'freq']

    df_doc_word_freq['word_freq'] = (
        df_doc_word_freq.base_form +
        ' ' +
        df_doc_word_freq.freq.astype(str)
    )
    df_result = (
        df_doc_word_freq
        .groupby(['id', 'original_text'])
        .word_freq
        .apply(' '.join)
    )
    return df_nouns_frequency, df_doc_word_freq, df_result


def plda_train(
    model_path,
    training_data_path: Optional[str] = None,
    df_parsed_train: Optional[pd.core.frame.DataFrame] = None,
    return_result: bool = True,
    **hyper_params
):
    if not (bool(training_data_path) ^ bool(df_parsed_train)):
        raise ValueError('Either training_data_path or df_parsed_train must be given.')

    with ExitStack() as stack:
        if df_parsed_train:
            tmp_train = stack.enter_context(NamedTemporaryFile())
            (shape_plda_input(df_parsed_train)[2]
             .to_csv(tmp_train.name, index=False))
            training_data_path = tmp_train.name

        hyper_params.update(
            model_file=model_path,
            training_data_file=training_data_path
        )

        option_str = ' '.join([
            f'--{k} {v}'
            for k, v
            in hyper_params.items()
        ])
        cmd = f"{TRAIN_PATH} {option_str}"
        call(cmd.split())
        if return_result:
            return load_plda_model(model_path)


def load_plda_model(
    model_path: str,
    normalize: bool = True,
    word_as_index: bool = True,
):
    '''PLDA の実行結果のモデルを読み込む。

    Parameters
    ----------

    model_path: モデルへのパス
    normalize: True であればトピックベクターを正規化する。
    '''
    model_matrix = pd.read_csv(
        model_path,
        delimiter=r'\s+',
        header=None,
        index_col=[0],
        engine='python'
    )
    topic_cols = [f'topic_{i}' for i in range(len(model_matrix.columns))]
    model_matrix.columns = topic_cols
    model_matrix.index.names = ['word']
    if normalize:
        model_matrix = model_matrix.apply(lambda s: s / s.sum())
    if not word_as_index:
        model_matrix = model_matrix.reset_index()
    return model_matrix


def plda_infer(
    model_path: str,
    inference_result_path: Optional[str] = None,
    inference_data_path: Optional[str] = None,
    df_parsed_infer: Optional[pd.core.frame.DataFrame] = None,
    return_result: bool = True,
    n_minimum_words: int = 1,
    normalize: bool = True,
    **hyper_params
):
    if not (bool(inference_data_path) ^ (df_parsed_infer is not None)):
        raise ValueError('Either inference_data_path or df_parsed_infer must be given.')

    if (inference_result_path is None) and (return_result == False):
        raise ValueError('return_result must be True if inference_data_path is not set.')

    with ExitStack() as stack:
        if df_parsed_infer is not None:
            tmp_infer = stack.enter_context(NamedTemporaryFile())
            (shape_plda_input(df_parsed_infer, n_minimum_words=n_minimum_words)[2]
             .to_csv(tmp_infer.name, index=False))
            inference_data_path = tmp_infer.name

        if inference_result_path is None:
            tmp_result = stack.enter_context(NamedTemporaryFile())
            inference_result_path = tmp_result.name

        hyper_params.update(
            model_file=model_path,
            inference_data_file=inference_data_path,
            inference_result_file=inference_result_path,
        )
        option_strs = []
        for k, v in hyper_params.items():
            option_strs.append(f'--{k}')
            option_strs.append(f'{v}')
        cmd = [INFER_PATH] + option_strs
        return_code = call(cmd)
        if return_code < 0:
            raise RuntimeError

        if return_result:
            df_result = df_parsed_infer[['id', 'original_text']].drop_duplicates()
            df_result.columns = ['id', 'doc']
            df_topics = pd.read_csv(
                inference_result_path,
                delimiter=' ',
                header=None,
            )
            if normalize:
                df_topics = df_topics.apply(lambda s: s / s.sum(), axis=1)
            topic_cols = [f'topic_{i}' for i in range(len(df_topics.columns))]
            df_topics.columns = topic_cols
            df_result = pd.concat([df_result, df_topics], axis=1)
            return df_result


def infer(
    df_model: pd.core.frame.DataFrame,
    df_parsed: pd.core.frame.DataFrame,
):
    df_parsed_topic = df_parsed.merge(
        df_model,
        left_on='base_form',
        right_on='word',
        how='inner'
    )
    df_parsed_topic.filter(regex=r'(id|original_text|topic_\d+|)')
    df_parsed_topic = (
        df_parsed_topic
        .groupby(['id', 'original_text'])
        .sum()
        .apply(lambda s: s / s.sum(), axis=1)
        .rename(columns={'original_text': 'doc'})
    )
    return df_parsed_topic
