"""SciLuigi / Luigi 用の Task の拡張"""
import luigi
import sciluigi

from .targets import CSVTarget, CSVTargetInfo, PickleTarget, PickleTargetInfo


class AutoLoadTask(sciluigi.Task):
    """Task that load in_xx attributes automatically."""

    def process(self, **kwargs):
        raise NotImplementedError

    def run(self):
        loaded_targets = {
            k: v().load()
            for k, v
            in self.__dict__.items()
            if k.startswith('in_')
        }
        self.process(**loaded_targets)


class ExistingFile(luigi.ExternalTask):
    '''External task for getting hand on existing files'''

    # PARAMETERS
    file_path = luigi.Parameter()
    file_format = luigi.parameter.ChoiceParameter(
        choices=['csv', 'pickle', 'other'],
        default = 'csv',
    )

    # TARGETS
    def output(self):
        if self.file_format == 'csv':
            return CSVTarget(self.file_path)
        elif self.file_format == 'pickle':
            return PickleTarget(self.file_path)


class ExistingFileSL(sciluigi.ExternalTask):
    '''External task for getting hand on existing files'''

    # PARAMETERS
    file_path = luigi.Parameter()
    file_format = luigi.parameter.ChoiceParameter(
        choices=['csv', 'pickle', 'other'],
        default = 'csv',
    )

    # TARGETS
    def out_file(self):
        if self.file_format == 'csv':
            return CSVTargetInfo(self, self.file_path)
        elif self.file_format == 'pickle':
            return PickleTargetInfo(self, self.file_path)


class RunRScript(luigi.Task):
    """Run a R script"""

    command = luigi.Parameter(default='Rscript')
    script_path = luigi.Parameter()
    args = luigi.ListParameter()

    def run(self):
        self.ex(f'{self.command} {self.script_path} {" ".join(self.args)}')


class RunRScriptSL(sciluigi.Task):
    """Run a R script"""

    command = luigi.Parameter(default='Rscript')
    script_path = luigi.Parameter()
    args = luigi.ListParameter()

    def run(self):
        self.ex(f'{self.command} {self.script_path} {" ".join(self.args)}')

