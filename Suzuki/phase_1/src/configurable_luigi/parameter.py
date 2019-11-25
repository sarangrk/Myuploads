import luigi
import traitlets

__all__ = [
    'ListParameter',
    'UnicodeParameter',
    'BoolParameter',
    'FloatParameter',
]


def make_traittype_param(traittype_cls, param_cls, cls_name, common_kwargs={}):

    class NewParameter(param_cls):

        def _initialize_param(self, *args, **kwargs):
            # Keyword args passed to TraitType but not used is
            # put in `metadata` attribute.
            new_kwargs = {
                k: v
                for k, v
                in kwargs.items()
                if (k in common_kwargs)
            }
            new_kwargs.update(**self.metadata)
            new_kwargs.pop('config', None)
            super().__init__(**new_kwargs)

    class NewClass(traittype_cls, NewParameter):

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            super()._initialize_param()
    
    NewClass.__qualname__ = cls_name
   
    return NewClass 


BoolParameter = make_traittype_param(traitlets.Bool, luigi.BoolParameter, 'BoolParameter')
FloatParameter = make_traittype_param(traitlets.Float, luigi.FloatParameter, 'FloatParameter')
ListParameter = make_traittype_param(traitlets.List, luigi.ListParameter, 'ListParameter')
UnicodeParameter = make_traittype_param(traitlets.Unicode, luigi.Parameter, 'UnicodeParameter')
