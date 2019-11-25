import argparse
from collections import Counter

import luigi
import numpy as np
import pandas as pd

from utils.targets import CSVTarget, JSONTarget

def make_strs_unique(strs):
    result = []
    c = Counter()
    for s in strs:
        if c[s] == 0:
            result.append(s)


def _calc_ginis(df_target):
    return (
        df_target
        .assign(
            n_false=lambda df: (~df.is_target).cumsum(),
            n_true_reverse=lambda df: df.loc[::-1, 'is_target'].cumsum()[::-1]
        )
        .assign(
            p_nega=lambda df: df.n_false / (df.index + 1),
            p_posi=lambda df: df.n_true_reverse.shift(-1) / (df.index[::-1]),
        )
        .assign(
            gini_nega=lambda df: df.eval('2 * p_nega * (1 - p_nega)'),
            gini_posi=lambda df: df.eval('2 * p_posi * (1 - p_posi)'),
        )
        .assign(
            remainder=lambda df:
               (df.gini_nega * (df.index + 1) + df.gini_posi * df.index[::-1]) / df.shape[0])
    )

def _calc_target_responces(df_target):
    return (
        df_target
        .assign(
            n_true=lambda df: df.is_target.cumsum(),
            n_true_reverse=lambda df: df.loc[::-1, 'is_target'].cumsum()[::-1]
        )
        .assign(
            p_nega=lambda df: df.n_true / (df.index + 1),
            p_posi=lambda df: df.n_true_reverse.shift(-1) / (df.index[::-1]),
        )
    )


def search_threshold(
    df_input,
    target,
    features,
    criteria = ['gini', 'responce'][0],
    target_col='parts',
    min_group_size=None,
) -> dict:
    try:
        thresholds = []

        feature_choices = list(map(lambda x: x.split(': '), features))
        used_features = list(set(f for f, c in feature_choices))
        df_target = (
            df_input[['id', 'doc'] + used_features + [target_col]]
            .assign(is_target=lambda df: df[target_col] == target)
        )
        average_response = df_target.is_target.sum() / df_target.shape[0]

        for feature, choice in feature_choices:
            df_target.sort_values(feature, inplace=True)
            df_target.reset_index(drop=True, inplace=True)
            if criteria == 'gini':
                df_target = _calc_ginis(df_target)
                min_remainder = df_target.loc[(df_target[feature] != df_target[feature].shift(-1)).fillna(True), 'remainder'].min()
                threshold, = df_target.query('remainder == @min_remainder')[feature].tail(1)
            elif criteria == 'responce':
                if set(df_target[feature].drop_duplicates().tolist()).issubset({0, 1}):
                    # 二値変数であるダミー変数に対しては特別扱い
                    threshold = 0
                    if choice == 'Y':
                        df_target = df_target[df_target[feature] == 1]
                    else:
                        df_target = df_target[df_target[feature] == 0]
                else:
                    df_target = _calc_target_responces(df_target)
                    if choice == 'Y':
                        ps_border = (
                            df_target
                            .loc[(df_target[feature] != df_target[feature].shift(-1)).fillna(True), 'p_posi']
                        )
                        n_trunc = min(min_group_size, int(ps_border.shape[0] * 0.05))
                        if n_trunc != 0:
                            ps_border = ps_border[n_trunc:-n_trunc]
                        max_responce = ps_border.max()
                        threshold, = df_target.query('p_posi == @max_responce')[feature].tail(1)
                        df_target = df_target[threshold < df_target[feature]]
                    else:
                        ps_border = (
                            df_target
                            .loc[(df_target[feature] != df_target[feature].shift(1)).fillna(True), 'p_nega']
                        )
                        n_trunc = min(min_group_size, int(ps_border.shape[0] * 0.05))
                        if n_trunc != 0:
                            ps_border = ps_border[n_trunc:-n_trunc]
                        max_responce = ps_border.max()
                        threshold, = df_target.query('p_nega == @max_responce')[feature].tail(1)
                        df_target = df_target[df_target[feature] <= threshold]
            else:
                raise ValueError('invalid `criteria`')

            thresholds.append(threshold)

        target_response = (df_target.is_target.sum()) / df_target.shape[0]
        lift = target_response / average_response
        n_rows = min(5, df_target.shape[0])
        return {
            'thresholds': thresholds,
            'ID': df_target.id[-n_rows:],
            'doc': df_target.doc[-n_rows:],
            'average_response': average_response,
            'target_response': target_response,
            'lift': lift,
            'n_pattern': df_target.shape[0],
        }
    except Exception as ex:
        import traceback
        # from ipdb import set_trace; set_trace()
        return {
            'thresholds': np.nan,
            'ID': np.nan,
            'average_response': average_response,
            'target_response': np.nan,
            'lift': np.nan,
            'n_pattern': np.nan,
        }


def search_thresholds_dataframe(df_input, df_patterns, last_node):
    # TODO last_node は自動的に検出したい
    if df_patterns.shape[0] == 0:
        return df_patterns
    from ipdb import set_trace; set_trace()
    df_patterns_ends_with_parts = df_patterns[df_patterns[last_node].str.match('^[0-9]* .*')]

    df_stats = (
        df_patterns_ends_with_parts
        .filter(regex=r'node.*')
        .apply(
            lambda r: search_threshold(
                df_input,
                r.tail(1).values[0],
                r[:-1].tolist(),
                criteria='responce',
                min_group_size=10),
            axis=1,
            result_type='expand',
        )
    )
    df_result = pd.concat([
        df_patterns_ends_with_parts,
        df_stats,
    ], axis=1)
    return df_result


class SearchThresholds(luigi.Task):
    '''与えられた部品の分類のために最適な特徴量の閾値を求める'''

    # 閾値を探す特徴量のリスト
    # それぞれ '{特徴量の名前}: (Y|N)' という形式の文字列
    features = luigi.ListParameter()
    # 結果
    target = luigi.Parameter()
    outfilename = luigi.Parameter()

    def output(self):
        return JSONTarget(self.outfilename)

    def run(self):
        df_input, = self.input()
        result = search_threshold(df_input, self.target, self.features)
        self.output().save()


class SearchThresholdsDataFrame(luigi.Task):
    '''与えられた部品の分類のために最適な特徴量の閾値を求める'''

    features_filename = luigi.Parameter()
    pattern_filename = luigi.Parameter()
    outfilename = luigi.Parameter()

    criteria = luigi.ChoiceParameter(choices=['gini', 'responce'])

    def requires(self):
        yield CSVTarget(self.features_filename)
        yield CSVTarget(self.pattern_filename)

    def output(self):
        return CSVTarget(self.outfilename)

    def run(self):
        df_input, df_patterns = [
            target.load()
            for target
            in self.input()
        ]
        df_result = search_thresholds_dataframe(
            df_input,
            df_patterns,
        )
        self.output().save(df_result)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--feature_path', required=True)
    parser.add_argument('--pattern_path', required=True)
    parser.add_argument('--out_path', required=True)

    luigi.build()
