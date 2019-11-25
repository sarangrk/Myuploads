import inspect
import pathlib
import shlex
from collections import deque
from subprocess import Popen, PIPE
from tempfile import NamedTemporaryFile
from typing import Iterable, List, Optional, Sequence, Tuple

import networkx
import numpy
import pandas as pd
from graphviz import Digraph
from sklearn.tree import DecisionTreeClassifier
from sklearn.tree.tree import Tree


PRJ_ROOT = pathlib.Path(__file__).absolute().resolve().parent.parent.parent
SUBTREE_MINER_PATH = PRJ_ROOT / 'src' / 'treeminer' / 'vtreeminer'


def convert_tree_repr_to_dft(tree: Tree) -> List[int]:
    '''scikit-learn の木構造を深さ優先で横断した順番にノードを並べた表現にする'''
    children_left = tree.children_left
    children_right = tree.children_right

    # Initialize
    visited_nodes = set([0])
    ordered_repr = [0]
    node_stack : deque = deque([0])

    while node_stack:
        node = node_stack[-1]
        children = children_left[node], children_right[node]

        for child in children:
            if (child not in visited_nodes) and (child != -1):
                node_stack.append(child)
                visited_nodes.add(child)
                ordered_repr.append(child)
                break
        else:
            node_stack.pop()
            ordered_repr.append(-1)

    return ordered_repr[:-1]


def convert_tree_repr_to_dft_with_choices(
    tree: Tree,
) -> List[List[int]]:
    '''scikit-learn の木構造を深さ優先で横断した順番にノードを並べた表現にする。

    木のどちらの方向に行ったのかを区別する。
    treeminer は木のどちらに行ったのかを区別しないため、
    抽出されたパターンに含まれるノードが良い影響なのか悪い影響なのかが判断できない。
    これらを区別するために、左に行く枝が出るノードと右に行く枝が出るノードを区別することにした。
    '''
    n_nodes = tree.node_count
    children_left = tree.children_left
    children_right = tree.children_right
    ordered_reprs = []

    # Initialize
    # 起点として仮想ノードを作る。
    start_node = n_nodes * 2
    visited_nodes = set([start_node])
    ordered_repr = [start_node]
    node_stack : deque = deque([start_node])

    while node_stack:
        node = node_stack[-1]
        if node == start_node:
            actual_child = 0
        elif node < n_nodes:
            # go left
            actual_child = children_left[node]
        else:
            # go right
            actual_child = children_right[node - n_nodes]

        if (actual_child == -1):
            # 終点ノード
            children = (-1, )
        elif (children_left[actual_child] == -1):
            # 子が終点ノードの時、Yes / No
            # どちらの枝かを区別して子ノードを入れる必要がないので片方だけ入れる。
            children = (actual_child, )
        else:
            # Yes / No 区別して子をたどる
            children = (actual_child, actual_child + n_nodes)

        for child in children:
            if (child not in visited_nodes) and (child != -1):
                node_stack.append(child)
                visited_nodes.add(child)
                ordered_repr.append(child)
                break
        else:
            node_stack.pop()
            ordered_repr.append(-1)

    ordered_reprs.append(ordered_repr[:-1])

    return ordered_reprs


def convert_dft_to_dot(
    dft_repr: List[int],
    features: List[str] = None,
    values: List[str] = None,
    support: float = None,
    choice_aware: bool = True,
):
    dot : Digraph = Digraph(comment=f'support = {support}')
    node_stack: deque = deque([(-1, None)])
    if (values is not None) and (features is not None):
        if choice_aware:
            labels: Optional[List[str]] = (
                [f + ': Y' for f in features]
                + [f + ': N' for f in features]
                + values
            )
        else:
            labels = features + values
    else:
        labels = None
    node_id = 0
    for node in dft_repr:
        par_node_id, par_node = node_stack[-1]
        if node == -1:
            node_stack.pop()
        else:
            node_stack.append((node_id, node))
            node_label = labels[node] if labels else str(node)
            dot.node(str(node_id), node_label)
            if par_node is not None:
                dot.edge(str(par_node_id), str(node_id))
            node_id += 1
    return dot


def extract_subtrees_from_treeminer_output(
    output: str
) -> List[Tuple[int, List[int]]]:
    out_lines = output.split('\n')
    result = []
    for line in out_lines[3:]:
        if line.startswith('F'):
            break
        if line.startswith('ITER'):
            continue
        if line == '':
            continue
        dft_repr, support_str = line.split(' - ')
        support = int(support_str)
        dft_tree = [int(node) for node in dft_repr.split()]
        result.append((support, dft_tree))
    return result


def mine_subtrees(
    trees: Iterable[DecisionTreeClassifier],
    feature_names: List[str],
    labels: List[str],
    min_support: float,
    miner=str(SUBTREE_MINER_PATH),
    choice_aware=True,
    out_path=None,
):
    with NamedTemporaryFile('w') as ofs:
        for i, tree in enumerate(trees):
            features = tree.tree_.feature
            n_nodes = tree.tree_.node_count
            values = numpy.argmax(tree.tree_.value, axis=2).flatten()

            def convert_node(node):
                '''convert_tree_repr... で得られた木構造表現のノードIDは
                決定木の中での一意に与えられたノードIDなので
                特徴量および分類結果のIDに変換する。
                '''
                if n_nodes * 2 <= node:
                    return len(features) + len(values) + i
                if n_nodes <= node:
                    actual_node = node - n_nodes
                else:
                    actual_node = node
                if actual_node == -1:
                    return node
                elif features[actual_node] == -2:
                    if choice_aware:
                        return values[actual_node] + len(feature_names) * 2
                    else:
                        return values[actual_node] + len(feature_names)
                else:
                    if choice_aware and (n_nodes <= node):
                        return features[actual_node] + len(feature_names)
                    else:
                        return features[actual_node]

            if choice_aware:
                dft_trees = convert_tree_repr_to_dft_with_choices(tree.tree_)
            else:
                dft_trees = [convert_tree_repr_to_dft(tree.tree_)]

            for dft_tree in dft_trees:
                dft_repr = [
                    str(convert_node(node))
                    for node
                    in dft_tree
                ]
                line = f'{i} {i} {len(dft_repr)} {" ".join(dft_repr)}\n'
                ofs.write(line)

        ofs.flush()

        # run external subtree miner
        args = shlex.split(f'{miner} -i {ofs.name} -s {min_support} -o')
        p = Popen(args, stdout=PIPE, stderr=PIPE)
        outs = []
        if out_path is not None:
            with open(out_path, 'wb') as ofs:
                for line in p.stdout:
                    ofs.write(line)
                    outs.append(line)
        out = b''.join(outs)
    return [
        (support, dft, convert_dft_to_dot(dft, features=feature_names, values=labels, support=support, choice_aware=choice_aware))
        for support, dft
        in extract_subtrees_from_treeminer_output(out.decode())
    ]


def extract_paths(subtrees, labels):
    df_paths_2 = pd.DataFrame.from_records(dict(
            node1=labels[dft[0]],
            node2=labels[dft[1]],
            support=support
        )
        for support, dft, _
        in subtrees
        if (len(dft) == 2) and (-1 not in dft)
    )
    df_paths_3 = pd.DataFrame.from_records(dict(
            node1=labels[dft[0]],
            node2=labels[dft[1]],
            node3=labels[dft[2]],
            support=support
        )
        for support, dft, _
        in subtrees
        if (len(dft) == 3) and (-1 not in dft)
    )
    df_paths_4 = pd.DataFrame.from_records(dict(
            node1=labels[dft[0]],
            node2=labels[dft[1]],
            node3=labels[dft[2]],
            node4=labels[dft[3]],
            support=support
        )
        for support, dft, _
        in subtrees
        if (len(dft) == 4) and (-1 not in dft)
    )
    return df_paths_2, df_paths_3, df_paths_4


def merge_nodes(G,nodes, new_node, attr_dict=None, **attr):
    """
    Merges the selected `nodes` of the graph G into one `new_node`,
    meaning that all the edges that pointed to or from one of these
    `nodes` will point to or from the `new_node`.
    attr_dict and **attr are defined as in `G.add_node`.
    """

    G.add_node(new_node, attr_dict, **attr) # Add the 'merged' node

    for n1,n2,data in G.edges(data=True):
        # For all edges related to one of the nodes to merge,
        # make an edge going to or coming from the `new gene`.
        if n1 in nodes:
            G.add_edge(new_node,n2,data)
        elif n2 in nodes:
            G.add_edge(n1,new_node,data)

    for n in nodes: # remove the merged nodes
        G.remove_node(n)


def make_merged_graph(df):
    g = networkx.DiGraph()
    g.add_nodes_from(df.node3)
    g.add_nodes_from(df.node2)
    g.add_nodes_from(df.node1)
    g.add_edges_from(list(df[['node1', 'node2']].itertuples(index=False)))
    g.add_edges_from(list(df[['node2', 'node3']].itertuples(index=False)))
    return g


def merge_from_start(df, start):
    df = (
        df
        .query('node1 == @start')
        .assign(node2=lambda df: df.node2 + '_2')
    )
    g = networkx.DiGraph()
    g.add_nodes_from(df.node3)
    g.add_nodes_from(df.node2)
    g.add_nodes_from(df.node1)
    g.add_edges_from(list(df[['node1', 'node2']].itertuples(index=False)))
    g.add_edges_from(list(df[['node2', 'node3']].itertuples(index=False)))
    return g


def draw_from_start_3nodes(
    df,
    start,
    min_lift,
    label_dict,
    min_n_patterns
):
    def rep_topic_str(topic_col):
        return (
            topic_col
            .str
            .replace(
                r'topic_\d*',
                lambda m: label_dict[m.group(0)]
            )
            .str[:-2]
        )
    def _add_nodes_from(g, nodes, **attr):
        for node, label in zip(nodes, rep_topic_str(nodes)):
            if node.startswith('topic_'):
                shape = 'box'
            else:
                shape = 'oval'
            g.add_node(
                node,
                label=label,
                shape=shape,
                **attr
            )
    df = (
        df
        .query("@min_lift < lift")
        .query("@min_n_patterns < n_patterns")
        .query('node1 == @start')
        .assign(
            node1=lambda df: df.node1 + '_1',
            node2=lambda df: df.node2 + '_2',
            node3=lambda df: df.node3 + '_3',
        )
    )
    g = networkx.DiGraph()

    _add_nodes_from(
        g,
        df.node3,
        fillcolor='darkorange',
        style='filled'
    )
    _add_nodes_from(g, df.node2)
    _add_nodes_from(g, df.node1)
    g.add_edges_from(list(df[['node1', 'node2']].itertuples(index=False)))
    for node2, node3, lift in df[['node2', 'node3', 'lift']].itertuples(index=False):
        g.add_edge(node2, node3, penwidth=log(lift + 1, 2))
    g.graph['graph'] = {'rankdir': 'LR'}
    return g
