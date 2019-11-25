import argparse
import inspect
import os
import pathlib
import sys
from functools import reduce
from typing import Dict, List, Tuple

import luigi
import pandas as pd
from progressbar import ProgressBar

PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent
sys.path.append(str(PRJ_ROOT / 'src'))

from cv_models import (
    KFoldCrossValidateSingleModel,
    ValidateModelBase,
    dict_to_index
)
from utils.targets import CSVTarget


def concat_valid_tables(
    dfs: List[List[Tuple[pd.core.frame.DataFrame, pd.core.frame.DataFrame]]],
    targets: List[Dict]
) -> pd.core.frame.DataFrame:
    '''評価用のテーブルを全て結合する。

    return value:

        id, proba, **[targetsの内容] の3以上の列を持つ DataFrame
    '''
    dfs_result = []
    for dfs_tuples, target in zip(dfs, targets):
        for _, df_valid in dfs_tuples:
            dfs_result.append(
                df_valid[['id', 'proba']]
                .assign(**target)
                .set_index(['id'] + list(target.keys()), drop=True)
            )
    return pd.concat(dfs_result, axis=0).reset_index()


def fill_validation_tables(
    df_topic_with_parts: pd.core.frame.DataFrame,
    df_validation: pd.core.frame.DataFrame,
    df_target: pd.core.frame.DataFrame,
    df_group: pd.core.frame.DataFrame,
    models: List,
    seed,
    topn: int = 5,
    extract_every: int = 50,
):
    '''評価用のテーブルの穴を埋める。

    models: list[estimator] 学習モデル
    '''

    def extract_topn(dfs):
        df_concat = pd.concat(dfs)
        if topn == -1:
            return df_concat
        df_topn = (
            df_concat
            .sort_values(['id', 'proba'], ascending=False)
            .groupby('id')
            .head(topn)
        )
        return df_topn

    df_topic_with_parts = df_topic_with_parts.sample(n=1000, random_state=seed)
    df_validation = df_validation[df_validation.id.isin(df_topic_with_parts.id)]

    cols = list(df_target.columns) + list(df_group.columns)
    df_doc = df_topic_with_parts[['id', 'doc'] + cols]
    df_predict = df_topic_with_parts.filter(regex=r'(id|topic_[0-9]+)', axis=1)
    dfs_result = []
    for i, (model, (_, target), (_, group)) in enumerate(zip(models, df_target.iterrows(), df_group.iterrows())):
        df_calculated = (
            df_validation[dict_to_index(df_validation, target)]
        )
        used_records = (
            (~df_predict.id.isin(df_calculated.id)).values &
            dict_to_index(df_predict, group).values
        )
        df_result = df_predict[used_records]

        X = (
            df_result
            .filter(regex=r'topic_[0-9]+', axis=1)
        )
        proba = model.predict_proba(X)[:, 1]
        df_result = (
            df_result[['id']]
            .assign(proba=proba, **dict(target, **group))
            .assign(predicted_parts_name=lambda df: df.parts_name)
        )
        dfs_result.append(df_result)
        dfs_result.append(df_calculated.assign(predicted_parts_name=df_calculated.parts_name)[df_result.columns])

        if (i % extract_every) == 0:
            df_result = [extract_topn(dfs_result)]

    df_result = df_doc.merge(extract_topn(dfs_result).drop(cols, axis=1), on='id')
    return df_result


class GenerateCandidateParts(ValidateModelBase):
    '''部品リストを生成する。
    '''

    target_cols = luigi.ListParameter(
        default=['parts_name', ]
    )
    grouping_cols = luigi.ListParameter(
        # default=['cluster_id', ]
        default=[]
    )
    topn = luigi.IntParameter(default=-1)
    sample_seed = luigi.Parameter(default=0)

    def output(self):
        targets = "_".join(self.target_cols)
        groups = "_".join(self.grouping_cols)
        filename = f'candidate_parts-{targets}-{groups}-seed={self.seed}-topn={self.topn}.csv'
        return CSVTarget(os.path.join(self.dirname, filename))

    def run(self):
        df_clustered_docs, df_component_table = [
            tgt.load()
            for tgt
            in self.input()
        ]
        cv_model_tasks = []
        df_clustered_docs = (
            df_clustered_docs
            .merge(df_component_table, on='id')
            .dropna(subset=['parts_name'])
        )
        if 'cluster_id' in df_clustered_docs.columns:
            # 「その他」のクラスタを統合するための ad hoc なコード
            df_clustered_docs = (
                df_clustered_docs
                .assign(
                    cluster_id=lambda df: df.cluster_id.replace({5: 2, 6: 2, 7: 2}))
            )
        merged_cols = list(self.target_cols) + list(self.grouping_cols)

        df_target = df_clustered_docs[list(merged_cols)].drop_duplicates()
        p = ProgressBar(maxval=df_target.shape[0]).start()
        rows = list(df_target.iterrows())
        targets = []
        groups = []
        for i, (_, values) in enumerate(rows):
            p.update(i)
            merged_dict = values.to_dict()
            target_dict = values[list(self.target_cols)].to_dict()
            grouping_dict = values[list(self.grouping_cols)].to_dict()
            if dict_to_index(df_clustered_docs, merged_dict).sum() > 15:
                targets.append(target_dict)
                groups.append(grouping_dict)
                cv_model_tasks.append(KFoldCrossValidateSingleModel(
                    clustered_docs_path=self.clustered_docs_path,
                    target_dict=target_dict,
                    grouping_dict=grouping_dict,
                ))
        p.finish()
        yield cv_model_tasks
        df_target = pd.DataFrame(targets)
        df_group = pd.DataFrame(groups)
        dfs = [task.out_df_pkl().load() for task in cv_model_tasks]
        modelss = [task.out_models_pkl().load() for task in cv_model_tasks]
        df_validation = concat_valid_tables(dfs, targets)
        df_result = fill_validation_tables(
            df_clustered_docs,
            df_validation,
            df_target,
            df_group,
            [models[0] for models in modelss],
            seed=self.sample_seed,
            topn=self.topn,
        )
        self.output().save(df_result)


class CalculateHitRate(GenerateCandidateParts):

    target_cols = luigi.ListParameter(
        default=['parts_name', ]
    )
    grouping_cols = luigi.ListParameter(
        # default=['cluster_id', ]
        default=[]
    )
    topn = None
    topns = luigi.ListParameter(default=[5, 10, 30])

    def output(self):
        targets = "_".join(self.target_cols)
        groups = "_".join(self.grouping_cols)
        filename = f'candidate_parts_hit_rate-{targets}-{groups}-seed={self.seed}-.csv'
        return CSVTarget(os.path.join(self.dirname, filename))

    def requires(self):
        return GenerateCandidateParts(
            clustered_docs_path=self.clustered_docs_path,
            target_cols=self.target_cols,
            grouping_cols=self.grouping_cols,
            sample_seed=self.sample_seed,
            topn=max(self.topns)
        )

    def run(self):
        df_candidate_parts = self.input().load()
        for n in self.topns:
            df_candidate_parts = (
                df_candidate_parts
                .assign(collect=lambda df: df.parts_name == df.predicted_parts_name)
            )

        dfs = []
        for n in self.topns:
            df_result_part = (
                df_candidate_parts
                .groupby('id')
                .apply(
                    lambda df: (
                        df
                        .sort_values('proba')
                        .head(n)
                        .collect
                        .any()
                    )
                )
                .to_frame(f'hit_{n}')
                .reset_index()
            )
            dfs.append(df_result_part)

        df_result = reduce(
            lambda df1, df2: df1.merge(df2),
            dfs,
            df_candidate_parts[['id', 'doc', 'parts_name']].drop_duplicates()
        )
        self.output().save(df_result)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'input_csv_path',
        help='入力データとなる文書ごとのトピックCSVのパスです。'
    )
    args = parser.parse_args()
    # 実行
    main_task = CalculateHitRate(
        clustered_docs_path=args.input_csv_path,
    )
    luigi.build(
        tasks=[main_task],
        workers=6,
        local_scheduler=True,
    )
