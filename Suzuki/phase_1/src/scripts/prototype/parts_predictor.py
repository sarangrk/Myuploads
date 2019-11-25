import inspect
from pathlib import Path
from operator import itemgetter
from traceback import print_exc
import pickle as pkl
import re
import sys
from argparse import ArgumentParser
from typing import List, Tuple

import pandas as pd
from pandas.core.frame import DataFrame

PRJ_ROOT = Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent.parent
sys.path.append(str(PRJ_ROOT / 'src'))


from scripts.get_similar_docs import SimilarDocFinder
from transform.parse import chasen_parse_texts
from transform.vectorize_text import plda_topicalize
from transform.plda import load_plda_model


class PartsPredictor(object):

    def __init__(
        self,
        predict_model_dir: str,
        topic_model_path: str,
        file_match_pattern: str,
    ) -> None:
        self._df_topic_model = load_plda_model(
            topic_model_path,
            normalize=True,
            word_as_index=True
        )

        self._models: dict = dict()
        file_match = re.compile(file_match_pattern)
        for path in Path(predict_model_dir).iterdir():
            search = file_match.match(str(path)) 
            if not search:
                continue
            parts_name = search.group(1)
            with path.open('rb') as infile:
                model = pkl.load(infile)[0]
                self._models[parts_name] = model
            
    def predict(self, text: str) -> List[Tuple[str, float]]:
        topic = (
            plda_topicalize(text, self._df_topic_model)[1]
            .filter(regex=r'topic_\d+', axis=1)
            .values
        )
        result: List[Tuple[str, float]] = []
        for parts_name, model in self._models.items():
            proba = model.predict_proba(topic)[0, 1]
            result.append((parts_name, proba))
        result.sort(key=itemgetter(1), reverse=True)
        return result


def enter_main_loop(
    predict_model_dir: str,
    topic_model_path: str,
    file_match_pattern: str,
    topn: int,
    verbosity: int,
):
    predictor = PartsPredictor(
        predict_model_dir,
        topic_model_path,
        file_match_pattern
    )
    while True:
        try:
            in_text = input('> ')
            parts = predictor.predict(in_text)
            if verbosity >= 1:
                pass
            print(parts[:topn])
        except KeyboardInterrupt:
            raise
        except Exception:
            print_exc()
            pass

def main(argv=sys.argv):
    parser: ArgumentParser = ArgumentParser()
    parser.add_argument('predict_model_dir')
    parser.add_argument('topic_model_path')
    parser.add_argument(
        '--file_match_pattern',
        required=False,
        default=r'.*cv-RandomForestClassifier-parts_name=(((?!cluster_id=\d+).)*)--5fold-models\.pkl'
    )
    parser.add_argument(
        '--topn', 
        type=int,
        required=False,
        default=5,
    )
    parser.add_argument(
        '--verbosity',
        type=int,
        required=False,
        default=1,
    )
    args = parser.parse_args()
    enter_main_loop(
        args.predict_model_dir,
        args.topic_model_path,
        args.file_match_pattern,
        args.topn,
        args.verbosity
    )

if __name__ == '__main__':
    main()