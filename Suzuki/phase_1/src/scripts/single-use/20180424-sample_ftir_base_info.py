import os.path as path
from logging import getLogger

import luigi
import pandas as pd
import sciluigi as sl


logger = getLogger(__file__)


PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)
DATA_PATH = path.join(PRJ_ROOT, 'data')


def load_ftir_base_info():
    df = pd.read_csv(path.join(DATA_PATH, 'raw', 'FTIR_BASE_INFO_DATA_TABLE.csv'), encoding='cp932')
    return df


def sample_ftir_base_info(frac=0.001, random_state=0):
    df = load_ftir_base_info()
    df_sampled = df.sample(frac=frac, random_state=random_state)
    return df_sampled


class SampledFTIRBaseInfo(sl.Task):
    """サンプル済みFTIRデータ"""

    seed = luigi.Parameter(default=0)
    frac = luigi.FloatParameter(default=0.001)

    def out_pickle(self):
        filename = 'ftir_base_info_data_table_sampled_r{frac}_s{seed}.pkl'.format(
            frac=self.frac,
            seed=self.seed,
        )
        full_path = path.join(
            DATA_PATH,
            'interim',
            filename
        )
        return sl.TargetInfo(self, full_path)

    def out_excel(self):
        filename = 'ftir_base_info_data_table_sampled_r{frac}_s{seed}.xlsx'.format(
            frac=self.frac,
            seed=self.seed,
        )
        full_path = path.join(
            DATA_PATH,
            'interim',
            filename
        )
        return sl.TargetInfo(self, full_path)

    def run(self):
        df = sample_ftir_base_info(frac=self.frac, random_state=self.seed)
        df.to_pickle(self.out_pickle().path)
        writer = pd.ExcelWriter(self.out_excel().path, engine='xlsxwriter')
        df.to_excel(writer)


class MakeSampledData(sl.WorkflowTask):

    def workflow(self):
        return self.new_task(
            'sampled_ftir',
            SampledFTIRBaseInfo,
            frac=0.001,
        )


if __name__ == '__main__':
    sl.run_local(main_task_cls=MakeSampledData)
