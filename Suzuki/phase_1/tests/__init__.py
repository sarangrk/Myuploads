import inspect
import pathlib
import sys

PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent
sys.path.append(str(PRJ_ROOT / 'src'))
