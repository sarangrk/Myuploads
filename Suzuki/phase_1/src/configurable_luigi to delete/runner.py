'''An application which runs Luigi workflow.'''
import sys

import luigi
from traitlets import Dict, Type, Unicode
from traitlets.config import Config
from traitlets.config.application import Application


class WorkflowRunner(Application):

    config_file = Unicode(u'', help="Load this config file", config=True)

    main_task_cls = Type(luigi.Task, help="Main task.", config=True)
    params = Dict(default_value={}, help="Parameter of main task.", config=True)
    run_options = Dict(
        {'local_scheduler': True},
        help="Options thrown to `luigi.build()` function.",
        config=True
    )

    def initialize(self, *args, **kwargs):
        super().initialize(*args, **kwargs)
        if self.config_file:
            self.load_config_file(self.config_file)


    def start(self):
        main_task = self.main_task_cls(config=self.config, **self.params)
        luigi.build(
            tasks=[main_task],
            **self.run_options
        )


def main(argv=None, **kwargs):
    WorkflowRunner.launch_instance(argv=argv, **kwargs)


if __name__ == '__main__':
    main()
