import inspect
import pathlib
import sys

PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent
SRC_DIR = str(PRJ_ROOT / 'src')

if SRC_DIR not in sys.path: 
    sys.path.append(SRC_DIR)

