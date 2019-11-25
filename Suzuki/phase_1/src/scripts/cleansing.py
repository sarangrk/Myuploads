import inspect
import os.path as path
import pathlib
import pickle
import sys
from os import mkdir
from functools import reduce

import luigi
from traitlets import Dict, List, Type, Unicode, default, validate

PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent
DATA_PATH = PRJ_ROOT / 'data'
sys.path.append(str(PRJ_ROOT / 'src'))

from configurable_luigi import ConfigurableTask, WorkflowRunner
from data.cleansing import Cleansing
from data.load import LoadJP4WheelData
from transform.filter_word_types import FilterWordTypes
from transform.join_text import JoinText
from transform.parse import ParseDocs
from utils.targets import CSVTarget
from utils.tasks import AutoLoadTask


class _ExtractCleansedTextData(luigi.Task):

    col_names = luigi.ListParameter()
    out_filename = luigi.Parameter()

    def requires(self):
        yield Cleansing(config=self.config)
        yield LoadJP4WheelData(col_names=self.col_names, frac=1)

    def output(self):
       return CSVTarget(self.out_filename)

    def run(self):
        df_cleansed, df_text = [
            target.load()
            for target
            in self.input()
        ]
        df_result = df_cleansed.merge(df_text)
        self.output().save(df_result)


class ExtractCleansedTextData(ConfigurableTask, _ExtractCleansedTextData):

    col_names = List(
        default_value=[
            'F_ID',
            'F_FAULT_SUBJECT_LL',
            'F_FAULT_PROPOSAL_LL',
            'F_FAULT_WHEN_LL',
            'F_FAULT_SITUATION_LL',
            'F_FAULT_WHAT_LL',
            'F_FAULT_BECAME_LL',
            'F_FAULT_CHECK_LL',
            'F_FAULT_RESULT_LL',
            'F_FAULT_CAUSE_LL',
            'F_FAULT_WHY_LL',
        ],
        config=True,
    )
    @validate('col_names')
    def _valid_col_names(self, proposal):
        col_names = proposal['value']
        if 'F_ID' not in col_names:
            col_names = ['F_ID'] + col_names
        return col_names

    out_filename = Unicode(config=True)
    @default('out_filename')
    def _default_out_filename(self):
        filename = 'cleansed-text_' + '-'.join(self.col_names) + '.csv'
        return str(DATA_PATH / 'interim' / filename)


class JoinExtractedText(ConfigurableTask, JoinText):

    input_cls = ExtractCleansedTextData
    input_params : dict = {}
    id_col = 'F_ID'
    joined_col = 'DOC'
    keep_other_cols = False
    join_cols = List(
        config=True,
        default_value=[
            # 'F_FAULT_SUBJECT_LL',
            'F_FAULT_PROPOSAL_LL',
            'F_FAULT_WHEN_LL',
            'F_FAULT_SITUATION_LL',
            # 'F_FAULT_WHAT_LL',
            # 'F_FAULT_BECAME_LL',
            # 'F_FAULT_CHECK_LL',
            # 'F_FAULT_RESULT_LL',
            # 'F_FAULT_CAUSE_LL',
            # 'F_FAULT_WHY_LL',
        ]
    )
    @validate('join_cols')
    def _validate_join_cols(self, proposal):
        input_task = list(self.requires())[0]
        input_cols = set(input_task.col_names)
        assert all(col in input_cols for col in proposal['value'])
        return proposal['value']

    outfilename = Unicode(config=True)
    @default('outfilename')
    def _default_out_filename(self):
        filename = 'cleansed-text-joined_' + str(hash('-'.join(self.join_cols))) + '.csv'
        return str(DATA_PATH / 'interim' / filename)


class ParseJoinedDocs(ConfigurableTask, ParseDocs):

    input_cls = JoinExtractedText
    input_params : dict = {}
    doc_column_name = Unicode(default_value='DOC')
    @validate('doc_column_name')
    def _validate_doc_column_name(self, proposal):
        input_task = list(self.requires())[0]
        assert proposal['value'] == input_task.joined_col
        return proposal['value']

    engine = Unicode('chasen', config=True)
    dir_name = Unicode(config=True)
    @default('dir_name')
    def _default_dir_name(self):
        input_task = list(self.requires())[0]
        return input_task.outfilename.rsplit('.')[0]


class FilterParsedWords(ConfigurableTask, FilterWordTypes):

    input_cls = ParseJoinedDocs
    input_params = {}
    outfilename = Unicode(config=True)
    @default('outfilename')
    def _default_outfilename(self):
        head, tail = path.split(self.input()[0].path)
        return path.join(head, 'filtered-' + tail)


def main():
    WorkflowRunner.launch_instance(main_task_cls=FilterParsedWords)


if __name__ == '__main__':
    main()