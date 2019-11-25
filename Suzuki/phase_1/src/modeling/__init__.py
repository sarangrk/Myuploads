import inspect
import pathlib
import sys

PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent
SRC_DIR = PRJ_ROOT / 'src'

if SRC_DIR not in sys.path:
    sys.path.append(str(SRC_DIR))
