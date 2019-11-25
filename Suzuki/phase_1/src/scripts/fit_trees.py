"""決定木を作成するスクリプト

パラメータ設定は別ファイルに記述し、
```
python src/scripts/fit_trees.py --WorkflowRunner.config_file='path/to/config_file.py'
```
として呼び出す。

設定内容は fit_trees.config.py.example を参照すること。

"""
import inspect
import os.path as path
import pathlib
import pickle
import re
import sys
from itertools import starmap, chain

PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent
DATA_PATH = PRJ_ROOT / 'data'
sys.path.append(str(PRJ_ROOT / 'src'))


import luigi
import numpy as np
import pandas as pd
from sqlalchemy.sql import and_, func, or_
from sklearn.tree import DecisionTreeClassifier, export_graphviz
from sklearn.ensemble import RandomForestClassifier
from traitlets import Dict, Enum, Float, Integer, List, Type, Unicode, default
from traitlets.config import Configurable

sys.path.append(path.join(PRJ_ROOT, 'src'))

from configurable_luigi import ConfigurableTask, WorkflowRunner
from data.db import session_scope
from data.filter import filter_jp_4wheel_data, filter_by_trouble_complaint_code
from data.load import df_from_query
from data.models import FTIRBaseInfo, TYQ0210, TYQ0110
from utils.targets import CSVTarget, PickleTarget
from utils.tasks import ExistingFile


def normalize_columns(df):
    f_mileage = pd.to_numeric(df.F_MILEAGE, errors='coerce')
    df = df.assign(
        F_FCOK=pd.to_numeric(df.F_FCOK, errors='coerce'),
        F_MILEAGE=np.where(
            # Indicates F_MILEAGE is in Miles
            df.F_MILEAGE_UNIT == '2',
            # Make it in Kilometers
            f_mileage * 1.609,
            f_mileage),
        F_SELLING_MODEL_SIGN=df.F_SELLING_MODEL_SIGN.str[0:5],
    )
    if 'G_CAUSAL_PARTS_NO' in df.columns:
        df = df.assign(
            G_CAUSAL_PARTS_NO=df.G_CAUSAL_PARTS_NO.str[0:5],
        )
    return df


class WholePartsTable(luigi.Task):
    '''全件についての部品情報を FPCR から取得したテーブルを作成する。'''

    def output(self):
        return CSVTarget(path.join(DATA_PATH, 'interim', 'FPCR.csv'))

    def run(self):
        with session_scope() as session:
            query = (
                session
                .query(
                    FTIRBaseInfo.c.F_ID,
                    TYQ0110.c.G_FPCR_ID,
                    func.substr(TYQ0110.c.G_CAUSAL_PARTS_NO, 1, 5).label('G_CAUSAL_PARTS_NO'),
                    TYQ0110.c.G_CAUSAL_PARTS_NAME_PL,
                )
                .join(TYQ0210, FTIRBaseInfo.c.F_ID == TYQ0210.c.G_ID)
                .filter(TYQ0110.c.G_FPCR_ID == TYQ0210.c.G_FPCR_ID)
            )

            query = filter_jp_4wheel_data(query)
            df = df_from_query(query)

        df_parts_no = (
            df[['G_CAUSAL_PARTS_NO', 'G_CAUSAL_PARTS_NAME_PL']]
            .groupby('G_CAUSAL_PARTS_NO')
            .agg(lambda x:x.value_counts().index[0])
            .reset_index()
            .assign(parts=lambda df: df.G_CAUSAL_PARTS_NO + ' ' + df.G_CAUSAL_PARTS_NAME_PL)
            .drop('G_CAUSAL_PARTS_NAME_PL', axis=1)
        )
        df_result = (
            df[['F_ID', 'G_FPCR_ID', 'G_CAUSAL_PARTS_NO']]
            .merge(df_parts_no)
            .assign(fpcr=lambda df: df.G_FPCR_ID + '-' + df.parts)
        )

        self.output().save(df_result)


class _AdditionalFeatures(luigi.Task):

    target_trouble_codes = luigi.ListParameter()
    col_names = luigi.DictParameter()
    out_filename = luigi.Parameter()

    def output(self):
        return CSVTarget(self.out_filename)

    def run(self):

        with session_scope() as session:
            query = (
                session
                .query(*chain.from_iterable(
                    [getattr(globals()[table_name].c, col_name)
                     for col_name
                     in col_names
                    ]
                    for table_name, col_names
                    in self.col_names.items()
                ))
            )
            query = filter_jp_4wheel_data(query)
            query = filter_by_trouble_complaint_code(query, self.target_trouble_codes)
            df = df_from_query(query)
        df = normalize_columns(df).drop('F_MILEAGE_UNIT', axis=1)
        self.output().save(df)


class AdditionalFeatures(ConfigurableTask, _AdditionalFeatures):

    target_trouble_codes = List(config=True)
    col_names = Dict(config=True)
    out_filename = Unicode(config=True)

    @default('out_filename')
    def _default_out_filename(self):
        col_names_joined = '_'.join(
            f'{k}={"-".join(v)}'
            for k, v
            in self.col_names.items()
        )
        codes_joined = '-'.join(self.target_trouble_codes)
        filename = f'feashtures_{hash(col_names_joined)}_{codes_joined}.csv'
        return path.join(DATA_PATH, 'interim', filename)

class _CommonParams(luigi.Config):

    out_dir = luigi.Parameter()
    target_col = luigi.Parameter()


class CommonParams(Configurable):

    out_dir = Unicode(config=True)
    target_col = Unicode(default_value='fpcr', config=True)


class _MakeDecisionTreeInput(_CommonParams, luigi.Task):

    topic_task_class = luigi.TaskParameter()
    topic_params = luigi.DictParameter()

    additional_features_task_class = luigi.TaskParameter()
    additional_features_params = luigi.DictParameter()

    categorical_cols = luigi.ListParameter()

    target_task_class = luigi.TaskParameter()
    target_params = luigi.DictParameter()

    def requires(self):
        yield self.topic_task_class(**self.topic_params)
        yield self.additional_features_task_class(
            **self.additional_features_params,
            config=self.config
        )
        yield self.target_task_class(**self.target_params)

    def output(self):
        return {
            'learn_data': CSVTarget(path.join(self.out_dir, 'learn_data.csv')),
            'learn_data_dummy': PickleTarget(path.join(self.out_dir, 'learn_data_dummy.pkl')),
        }

    def run(self):
        outs = self.output()
        df_topic, df_features, df_fpcr = [
            target.load()
            for target
            in self.input()
        ]
        df_topic_features = (
            df_topic
            .merge(df_features, left_on='id', right_on='F_ID')
            .merge(df_fpcr[['F_ID', self.target_col]], left_on='id', right_on='F_ID')
            .drop(['F_ID_x', 'F_ID_y'], axis=1)
        )
        outs["learn_data"].save(df_topic_features)

        df_dummy_features = pd.get_dummies(
            df_features,
            columns=self.categorical_cols,
            prefix_sep='=',
        )
        df_topic_dummy_features = (
            df_topic
            .merge(df_dummy_features, left_on='id', right_on='F_ID')
            .merge(df_fpcr[['F_ID', self.target_col]], left_on='id', right_on='F_ID')
            .drop(['F_ID_x', 'F_ID_y'], axis=1)
            .dropna()
        )
        outs["learn_data_dummy"].save(df_topic_dummy_features)

class MakeDecisionTreeInput(ConfigurableTask, CommonParams, _MakeDecisionTreeInput):

    topic_task_class = ExistingFile
    topic_filename = Unicode(config=True)

    @property
    def topic_params(self):
        return {'file_path': self.topic_filename}

    additional_features_task_class = AdditionalFeatures
    additional_features_params : dict = {}

    categorical_cols = List(config=True)

    target_task_class =  Type(default_value=WholePartsTable, klass=luigi.Task, config=True)
    target_params = Dict(default_value={}, config=True)

# TODO ここから下の Fit 系のクラスで共通するパラメータがあるのは
# luigi.utils.inherits を使うと綺麗にかける
# cf: https://luigi.readthedocs.io/en/stable/api/luigi.util.html

class _FitDecisionTree(_CommonParams, luigi.Task):

    model_args = luigi.DictParameter()
    model_filename = luigi.Parameter()
    impurity_threshold = luigi.FloatParameter()

    def requires(self):
        yield MakeDecisionTreeInput(config=self.config)

    def output(self):
        return {
            'tree': PickleTarget(path.join(self.out_dir, f'{self.model_filename}.pkl')),
            'tree_dot': luigi.LocalTarget(path.join(self.out_dir, f'{self.model_filename}.dot')),
            'ambiguous_records': CSVTarget(path.join(self.out_dir, f'{self.model_filename}_ambiguous_records.csv')),
        }

    def run(self):
        inputs, = self.input()
        df_topic_features = inputs['learn_data'].load()
        df_topic_dummy_features = inputs['learn_data_dummy'].load()
        outs = self.output()
        tree = DecisionTreeClassifier(**self.model_args)
        filter_regex = r'topic_[0-9]*'
        df_X = df_topic_dummy_features.drop(['id', 'doc', self.target_col], axis=1)

        levels_topics, labels_topics = pd.factorize(df_topic_dummy_features[self.target_col].values)
        tree.fit(X=df_X, y=levels_topics)
        outs['tree'].save(tree)
        export_graphviz(
            tree,
            outs['tree_dot'].path,
            feature_names=df_X.columns,
            class_names=labels_topics,
            node_ids=True,
        )

        try:
            leaves = tree.apply(df_X)
            nodes = tree.tree_.__getstate__()['nodes']
            impurity_threshold = self.impurity_threshold
            df_impure = (
                df_topic_dummy_features[['id']]
                .assign(
                    leaf=leaves,
                    impurity=list(map(lambda leaf: nodes[leaf][4], leaves))
                )
                .merge(df_topic_features)
            )
            outs['ambiguous_records'].save(df_impure)
        except:
            from ipdb import set_trace; set_trace()


class FitDecisionTree(ConfigurableTask, CommonParams, _FitDecisionTree):

    impurity_threshold = Float(config=True)


class _FitRandomForest(_CommonParams, luigi.Task):

    model_args = luigi.DictParameter()
    model_filename = luigi.Parameter()

    def requires(self):
        yield MakeDecisionTreeInput(config=self.config)

    def output(self):
        return {
            'rf': PickleTarget(path.join(self.out_dir, f'{self.model_filename}.pkl')),
        }

    def run(self):
        inputs, = self.input()
        df_topic_features = inputs['learn_data'].load()
        df_topic_dummy_features = inputs['learn_data_dummy'].load()
        outs = self.output()
        rf = RandomForestClassifier(**self.model_args)
        filter_regex = r'topic_[0-9]*'
        df_X = df_topic_dummy_features.drop(['id', 'doc', self.target_col], axis=1)

        levels_topics, labels_topics = pd.factorize(df_topic_dummy_features[self.target_col].values)
        rf.fit(X=df_X, y=levels_topics)
        outs['rf'].save(rf)


class FitRandomForest(ConfigurableTask, CommonParams, _FitRandomForest, ):
    pass


class Fit(ConfigurableTask, luigi.WrapperTask):

    method = Enum(['dt', 'rf'], config=True, default='dt')
    model_args = Dict(config=True)
    model_filename = Unicode(config=True)

    def requires(self):
        if self.method == 'dt':
            yield FitDecisionTree(
                config=self.config,
                model_args=self.model_args,
                model_filename=self.model_filename,
            )
        elif self.method == 'rf':
            yield FitRandomForest(
                config=self.config,
                model_args=self.model_args,
                model_filename=self.model_filename,
            )
        else:
            raise ValueError('Invalid value for `Fit.method` (choose from {"dt", "rf"}.')


def main():
    WorkflowRunner.launch_instance(main_task_cls=Fit)


if __name__ == '__main__':
    main()
