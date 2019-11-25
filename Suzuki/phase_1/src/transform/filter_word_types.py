import luigi
import pandas

from utils.targets import CSVTarget
from utils.tasks import ExistingFile
from . import PRJ_ROOT


class FilterWordTypes(luigi.Task):

    input_cls = luigi.TaskParameter()
    input_params = luigi.DictParameter()
    used_word_types_filename = luigi.Parameter(
        default=str(PRJ_ROOT / 'data' / 'extern' / 'used_word_types.csv')
    )
    outfilename = luigi.Parameter()

    def requires(self):
        yield self.input_cls(**self.input_params, config=self.config)
        yield ExistingFile(self.used_word_types_filename)

    def output(self):
        return CSVTarget(self.outfilename)

    def run(self):
        df_words, df_used_word_types = [
            target.load()
            for target
            in self.input()
        ]

        df_word_type_split = pandas.concat(
            [df_words, df_words.word_class.str.split('-', expand=True)],
            axis=1,
        )
        df_word_type_split.columns = list(map(str, df_word_type_split.columns))
        df_result = (
            df_word_type_split
            .merge(df_used_word_types)
            .sort_values(['id', 'word_position'])
            .assign(used=True)
        )
        self.output().save(df_result)
