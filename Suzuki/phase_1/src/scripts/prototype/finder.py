import inspect
import pathlib
import sys
from argparse import ArgumentParser
from typing import Tuple

import pandas as pd
from pandas.core.frame import DataFrame

PRJ_ROOT = pathlib.Path(inspect.getfile(inspect.currentframe())).absolute().parent.parent.parent.parent
sys.path.append(str(PRJ_ROOT / 'src'))


from scripts.get_similar_docs import SimilarDocFinder
from transform.parse import chasen_parse_texts
from transform.vectorize_text import plda_topicalize
from transform.plda import load_plda_model


def find_similar_doc(
    finder: SimilarDocFinder,
    df_model: DataFrame,
    query_text: str,
    topn: int,
) -> Tuple[DataFrame, DataFrame, DataFrame]:
    '''類似文書を検索する。
    
    Parameters
    ----------
    
    finder: 検索対象の文章で初期化した Finder
    model_path: PLDA の学習済みモデルへのパス
    query_text: クエリ文
    model_args: モデルの学習パラメータ
    topn: 表示する文書の数
    '''
    df_parsed, df_doc_topic = plda_topicalize(query_text, df_model)
    df_similar_docs = finder.find_similar_docs_from_vector(
        df_doc_topic
        .filter(regex=r'topic_[0-9]+', axis=1)
        .values
    )
    return df_parsed, df_doc_topic, df_similar_docs


def enter_main_loop(
    doc2topic_path: DataFrame,
    model_path: str,
    topn: int,
    verbosity: int = 0
):
    df_doc2topic = pd.read_csv(doc2topic_path, encoding='utf-16', delimiter='\t')
    df_model = load_plda_model(model_path, normalize=True, word_as_index=False)
    finder = SimilarDocFinder.from_dataframe(df_doc2topic)
    while True:
        try:
            in_text = input('> ')
            df_parsed, df_doc_topic, df_similar_docs = find_similar_doc(
                finder, df_model, in_text, topn)
            if verbosity >= 1:
                print(df_parsed)
                print(df_doc_topic)
            print(df_similar_docs)
        except KeyboardInterrupt:
            raise
        else:
            pass


def main(argv=sys.argv):
    parser = ArgumentParser()
    parser.add_argument(
        'doc2topic_path',
        help='''文書のトピックベクターへのパス
文書のトピックベクターは id, doc, topic_xx (xx には0以上の数字) を持つ CSV である。'''
    )
    parser.add_argument(
        'model_path'
    )
    parser.add_argument(
        '--grouping_table_path',
        required=False,
        default='',
        help='''文書のグルーピング対応表へのパス
文書のグルーピング対応表は F_ID と GROUP の2列を持つCSVである。'''
    )
    parser.add_argument('--topn', required=False, type=int, default=5)
    parser.add_argument('--verbosity', required=False, type=int, default=1)

    args = parser.parse_args()
    enter_main_loop(
        args.doc2topic_path,
        args.model_path,
        args.topn,
        args.verbosity,
    )


if __name__ == '__main__':
    main()
