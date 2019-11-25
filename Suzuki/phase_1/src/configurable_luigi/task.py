"""Definition of ConfigurableTask class"""
from luigi import Task
from luigi.task_register import Register
from traitlets import MetaHasDescriptors, MetaHasTraits
from traitlets.config import Configurable


class MetaConfigurableTask(MetaHasTraits, MetaHasDescriptors, Register):
    pass


class ConfigurableTask(Configurable, Task, metaclass=MetaConfigurableTask):
    """Task class which utilizes traitlets configuration system."""
    
    @classmethod
    def get_param_values(cls, params, args, kwargs):
        # Override the method of `Task` class not to pass `config` parameter.
        kwargs = kwargs.copy()
        kwargs.pop('config', None)
        return super().get_param_values(params, args, kwargs)
