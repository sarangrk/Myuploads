from functools import reduce
from operator import itemgetter
import luigi

from utils.targets import CSVTarget

class JoinText(luigi.Task):

    config : dict = {}

    input_cls = luigi.TaskParameter()
    input_params = luigi.DictParameter()

    id_col = luigi.Parameter(default='')
    join_char = luigi.Parameter(default=' $ ')
    join_cols = luigi.ListParameter()
    joined_col = luigi.Parameter()
    keep_other_cols = luigi.BoolParameter()
    outfilename = luigi.Parameter()

    def output(self):
        return CSVTarget(self.outfilename)

    def requires(self):
        yield self.input_cls(**self.input_params, config=self.config)

    def run(self):
        df_input, = [
            target.load()
            for target
            in self.input()
        ]
        new_col = reduce(
            lambda a, b: a + self.join_char + b,
            itemgetter(*self.join_cols)(df_input.fillna(''))
        )
        if self.keep_other_cols:
            df_result = df_input.assign(**{self.joined_col: new_col})
        else:
            df_result = df_input[[self.id_col]].assign(**{self.joined_col: new_col})
        self.output().save(df_result)
