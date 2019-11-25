"""類似文書検索・列挙用スクリプト"""
from typing import Optional
from argparse import ArgumentParser

import numpy as np
import pandas as pd
from sklearn.neighbors import KDTree


class SimilarDocFinder(object):
    """Find similar documents from stored ones."""

    def __init__(
        self,
        docs: np.ndarray,
        topics: np.ndarray,
    ):
        # Construct KDTree based on Hellinger distance.
        self._docs = docs.reset_index(drop=True)
        self._kdtree = KDTree(topics.apply(np.sqrt))

    @classmethod
    def from_dataframe(cls, df_doc2topic: pd.core.frame.DataFrame):
        return cls(
            df_doc2topic.doc,
            df_doc2topic.filter(regex='topic', axis=1)
        )

    def find_similar_docs_from_vector(
        self,
        topic_vector: np.ndarray,
        k: int = 1
    ):
        dist, ind = self._kdtree.query(np.sqrt(topic_vector), k=k)
        return dist, self._docs[ind[0]]


def extract_similar_docs(
    df_doc2topic: pd.core.frame.DataFrame,
    min_doc_length: int,
    n_top: int,
    df_doc_ids: Optional[pd.core.frame.DataFrame] = None,
):
    if df_doc_ids is not None:
        df_doc_ids = df_doc_ids[['id']].merge(
            df_doc2topic,
            on='id',
            how='left'
        )
    df_filtered_docs = (
        df_doc_ids[
            min_doc_length <= df_doc_ids.doc.str.len()
        ]
    )
    finder = SimilarDocFinder.from_dataframe(df_doc2topic)
    n_top = min(df_doc2topic.shape[0] - 1, n_top)

    def find_result_to_data_frame(doc, topic_vector):
        # The first one is doc itself, so omit it.
        distance, docs = finder.find_similar_docs_from_vector([topic_vector], n_top + 1)
        return pd.DataFrame.from_items((
            ('doc', doc),
            ('rank', list(range(1, n_top + 1))),
            ('similar_doc', docs[1:]),
            ('distance', distance[0][1:])
        ))
    df_similar_docs = (
        pd.concat([
            find_result_to_data_frame(doc, row)
            for doc, row
            in df_filtered_docs.filter(regex='topic', axis=1).iterrows()
        ])
        .set_index(['doc', 'rank'])
        .stack()
        .unstack(level=-2)
        .unstack(level=-1)
    )
    df_result = df_filtered_docs.merge(df_similar_docs, left_index=True, right_index=True)
    df_result.columns = [
        '_'.join(map(str, col)).strip()
        if isinstance(col, tuple) else col
        for col
        in df_result.columns.values
    ]
    return df_result


def main(
    doc2topic_path: str,
    grouping_table_path: str,
    out_path: str,
    n_top: int = 5,
    min_doc_length: int = 300,
):
    df_doc2topic = pd.read_csv(doc2topic_path, encoding='utf-16', delimiter='\t')
    if grouping_table_path:
        df_doc_group = pd.read_csv(grouping_table_path, encoding='utf-16', delimiter='\t')
        df_doc2topic = df_doc2topic.merge(
            df_doc_group,
            left_on='id',
            right_on='F_ID',
            how='inner'
        )
    else:
        df_doc2topic = df_doc2topic.assign(GROUP=1)
    (df_doc2topic
     .groupby('GROUP')
     .apply(extract_similar_docs, min_doc_length, n_top)
     .to_csv(out_path, encoding='utf16', sep='\t')
    )


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument(
        'doc2topic_path',
        help='''文書のトピックベクターへのパス
文書のトピックベクターは id, doc, topic_xx (xx には0以上の数字) を持つ CSV である。
'''
    )
    parser.add_argument(
        'out_path',
        help='出力先'
    )
    parser.add_argument(
        '--grouping_table_path',
        required=False,
        default='',
        help='''文書のグルーピング対応表へのパス
文書のグルーピング対応表は F_ID と GROUP の2列を持つCSVである。'''
    )
    args = parser.parse_args()
    main(
        args.doc2topic_path,
        args.grouping_table_path,
        args.out_path,
    )
