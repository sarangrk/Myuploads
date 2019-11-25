import luigi
import sciluigi
from six import add_metaclass
from traitlets import Bool, Float, HasDescriptors, MetaHasTraits, MetaHasDescriptors, Unicode, default
from traitlets.config.configurable import Configurable

from configurable_luigi import BoolParameter, ConfigurableTask, FloatParameter, UnicodeParameter
from utils.targets import CSVTarget
from . import DATA_PATH
from .db import query_to_df, session_scope
from .filter import (
    drop_similar_str,
    drop_routine_inspection,
    filter_jp_4wheel_data,
    filter_newer,
    filter_received,
)
from .models import FTIRBaseInfo


class _Cleansing(luigi.Task):

    filter_received = luigi.BoolParameter()
    filter_newer = luigi.BoolParameter()
    drop_routine_inspection = luigi.BoolParameter()
    drop_similar_str = luigi.BoolParameter()
    similarity_rate = luigi.FloatParameter()
    out_filename = luigi.Parameter()

    def run(self):
        with session_scope() as session:
            query = session.query(
                FTIRBaseInfo.c.F_ID,
                FTIRBaseInfo.c.F_VIN,
                FTIRBaseInfo.c.F_FAULT_PROPOSAL_LL,
            )
            query = filter_jp_4wheel_data(query)

            if self.filter_received:
                query = filter_received(query)

            if self.filter_newer:
                query = filter_newer(query)

            df = query_to_df(query)

        if self.drop_routine_inspection:
            df = drop_routine_inspection(df)

        # 重複(文章内容が似ている)レコードの除外
        # 重複除外は最後にかける。
        # 他の条件で除外されるレコードと似ているレコードが余分に除外されるのを防ぐためである。
        if self.drop_similar_str:
            df = drop_similar_str(df, self.similarity_rate)

        self.output().save(df[['F_ID']].reset_index(drop=True))


class Cleansing(ConfigurableTask, _Cleansing):

    filter_received = Bool(default_value=True, config=True)
    filter_newer = Bool(default_value=True, config=True)
    drop_routine_inspection = Bool(default_value=True, config=True)
    drop_similar_str = Bool(default_value=True, config=True)
    similarity_rate = Float(default_value=0.5, config=True)
    out_filename = Unicode(config=True)
    @default('out_filename')
    def get_out_filename_default(self):
        return str(DATA_PATH / 'interim' / 'cleaned_data_20181105.csv')

    def output(self):
        return CSVTarget(self.out_filename)
