import inspect
import pathlib
import sys
from os import path
from typing import List

import luigi
import sciluigi as sl
import pandas as pd

from utils.targets import PickleTarget

from .db import session_scope
from .models import FTIRBaseInfo
from .filter import filter_jp_4wheel_data


PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent
DATA_PATH = str(PRJ_ROOT / 'data')


def load_jp_4wheel_data(col_names: List[str]) -> pd.core.frame.DataFrame:
    '''DB から、col_names に指定された列を国内四輪のデータを取り出す。'''
    with session_scope() as session:
        query = filter_jp_4wheel_data(
            session
            .query(*[getattr(FTIRBaseInfo.c, col_name) for col_name in col_names])
        )
        return pd.read_sql(query.statement, query.session.bind)


def df_from_query(query):
    return pd.read_sql(query.statement, query.session.bind)


class LoadJP4WheelData(luigi.Task):
    """指定された列の国内四輪データに絞って取得するタスク"""

    seed = luigi.IntParameter(default=0)
    frac = luigi.FloatParameter(default=0.4)
    col_names = luigi.ListParameter()

    def output(self):
        filename = 'FTIR_base_info_JP_4wheels_col_{col_names}_{frac}_s{seed}.pkl'.format(
            col_names=str(hash('-'.join(self.col_names))),
            frac=self.frac,
            seed=self.seed,
        )
        full_path = path.join(
            DATA_PATH,
            'interim',
            filename
        )
        return PickleTarget(full_path)

    def run(self):
        df = load_jp_4wheel_data(self.col_names)
        if self.frac != 1:
            df = df.sample(frac=self.frac, random_state=self.seed)
        self.output().save(df)


# class LoadPartsTable(luigi.Task):
#     """部品テーブルを生成するタスク"""
