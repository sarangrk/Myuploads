import inspect
from pathlib import Path
import sys
from os import path

import luigi
import pyximport; pyximport.install()
import sciluigi as sl
from tqdm import tqdm


PRJ_ROOT = Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent.parent

sys.path.append(str(PRJ_ROOT / 'src'))


from data.load import LoadJP4WheelData
from transform.parse import chasen_parse_texts
from utils.tasks import AutoLoadTask
from utils.targets import CSVTargetInfo, PickleTargetInfo


class ChasenParse(AutoLoadTask):

    in_df = None

    replace_katakana_hyphen = luigi.BoolParameter(default=True)

    @property
    def prefix(self):
        return (
            path.splitext(self.in_df().path)[0] +
            ('-rep_hyph' if self.replace_katakana_hyphen else '') +
            '_parsed'
        )

    def out_pickle(self):
        return PickleTargetInfo(self, self.prefix + '.pkl')

    def out_csv(self):
        return CSVTargetInfo(self, self.prefix + '.csv')

    def process(self, in_df):
        in_df = in_df.assign(
            F_FAULT_PROPOSAL_LL=in_df.F_FAULT_PROPOSAL_LL
            .str.replace('\r', '')
            .str.replace('\n', '')
            .str.strip()
        ).query("F_FAULT_PROPOSAL_LL != ''")
        in_df = in_df.assign(
            F_FAULT_PROPOSAL_LL=in_df.F_FAULT_PROPOSAL_LL
            .str.replace('ｰ', 'ー')
            .str.normalize('NFKC')
        )
        if self.replace_katakana_hyphen:
            in_df = in_df.assign(
                F_FAULT_PROPOSAL_LL=in_df.F_FAULT_PROPOSAL_LL
                .str.replace(r'([ァ-ヴ]+)[\?−\-]', r'\1ー')
            )
        df_chasen_parse = chasen_parse_texts(
            in_df.F_FAULT_PROPOSAL_LL,
            in_df.F_ID
        ).assign(
            used=lambda df: df.word_class.str.match('^(名詞[^数]*|未知語)$')
        )
        self.out_csv().save(df_chasen_parse)
        self.out_pickle().save(df_chasen_parse)


class MakeNGram(AutoLoadTask):

    in_df = None

    ns = luigi.ListParameter(default=[2, 3, 4, 5])

    def out_parsed_ngram_pickle(self):
        full_path = (
            path.splitext(self.in_df().path)[0] +
            '-ngram-{ns}.pkl'.format(ns='_'.join([str(i) for i in self.ns])))
        return PickleTargetInfo(self, full_path)

    def out_parsed_ngram_csv(self):
        full_path = (
            path.splitext(self.in_df().path)[0] +
            '-ngram-{ns}.csv'.format(ns='_'.join([str(i) for i in self.ns])))
        return CSVTargetInfo(self, full_path)

    def process(self, in_df):
        tqdm.pandas()
        parse_ngram = (
            in_df
            .query('used')
            .groupby(["id", "original_text"])
            .surface_form
            .progress_apply(katakana_ngram, self.ns)
        )
        parse_ngram.rename("surface_form", inplace=True)
        df_parse_ngram = parse_ngram.to_frame().assign(used=True)
        self.out_parsed_ngram_csv().save(df_parse_ngram)
        self.out_parsed_ngram_pickle().save(df_parse_ngram)

class ChasenParseWF(sl.WorkflowTask):

    seed = luigi.IntParameter(default=0)
    frac = luigi.FloatParameter(default=0.4)

    def workflow(self):
        load = self.new_task(
            'load',
            LoadJP4WheelData,
            col_names=['F_ID', 'F_FAULT_PROPOSAL_LL'],
            frac=self.frac,
            seed=self.seed,
        )
        parse = self.new_task('parse', ChasenParse)
        parse.in_df = load.out_pickle
        return parse


if __name__ == '__main__':
    sl.run_local(main_task_cls=ChasenParseWF)
