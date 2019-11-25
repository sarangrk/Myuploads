'''Luigi のタスクを走らせる Application'''
import sys

import luigi
from traitlets import Dict, Type, Unicode
from traitlets.config import Config
from traitlets.config.application import Application


class WorkflowRunner(Application):

    config_file = Unicode(u'', help="Load this config file").tag(config=True)

    main_task_cls = Type(luigi.Task)
    params = Dict({})
    run_options = Dict(dict(
        local_scheduler=True
    ))

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
