import argparse
import inspect
import pathlib
import pickle
import shlex
import sys
from collections import deque
from os import path
from subprocess import Popen, PIPE
from tempfile import NamedTemporaryFile
from typing import Iterable, List, Optional, Sequence, Tuple

import numpy
import pandas as pd
from graphviz import Digraph
from sklearn.tree import DecisionTreeClassifier
from sklearn.tree.tree import Tree

sys.path.append(path.join(path.dirname(__file__), path.pardir))

from modeling.mine_subtrees import extract_paths, mine_subtrees
from modeling.search_threshold import search_thresholds_dataframe


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('learn_data_path')
    parser.add_argument('rf_path')
    parser.add_argument('min_support', type=float)
    parser.add_argument('out_dir')

    args = parser.parse_args()

    with open(args.learn_data_path, 'rb') as infs:
        df_learn_data = pickle.load(infs)

    with open(args.rf_path, 'rb') as infs:
        rf = pickle.load(infs)

    features = df_learn_data.drop(['id', 'doc', 'parts'], axis=1).columns
    _, labels_topics = pd.factorize(df_learn_data['parts'].values)
    labels: Optional[List[str]] = (
        [f + ': Y' for f in features]
        + [f + ': N' for f in features]
        + list(labels_topics)
    )

    subtrees = mine_subtrees(
        rf.estimators_,
        feature_names=list(features),
        labels=labels,
        min_support=args.min_support,
        out_path='tmp.txt',
    )
    subtrees_path = path.join(args.out_dir, f'subtrees_minsup{args.min_support}.pkl')
    xlsx_path = path.join(args.out_dir, f'paths_minsup{args.min_support}.xlsx')
    with open(subtrees_path, 'wb') as st:
        pickle.dump(subtrees, st)
    dfs = extract_paths(subtrees, labels)
    with pd.ExcelWriter(xlsx_path, engine='xlsxwriter') as writer:
        (
            search_thresholds_dataframe(df_learn_data, dfs[0], 'node2')
            .to_excel(writer, sheet_name='path (2 nodes)')
        )
        (
            search_thresholds_dataframe(df_learn_data, dfs[1], 'node3')
            .to_excel(writer, sheet_name='path (3 nodes)')
        )
        (
            search_thresholds_dataframe(df_learn_data, dfs[2], 'node4')
            .to_excel(writer, sheet_name='path (4 nodes)')
        )
