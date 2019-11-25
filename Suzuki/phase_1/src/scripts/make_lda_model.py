'''LDA のモデルを計算するスクリプト'''
import argparse
import inspect
import logging
import os.path as path
import pathlib
import pickle
import sys
from operator import itemgetter
from os import mkdir
from functools import partial, reduce

import luigi
import numpy as np
import pandas as pd
import sciluigi as sl
import sys
from distance import nlevenshtein
from gensim import corpora
from gensim.models import LdaModel
from sklearn.neighbors import KDTree
from progressbar import ProgressBar

sys.path.append(path.join(path.dirname(__file__), path.pardir))

from data.load import LoadJP4WheelData, load_jp_4wheel_data
from transform.make_corpus import make_corpora_from_dataframe
from transform.parse import mecab_parse_texts
from transform.plda import shape_plda_input, plda_train, load_plda_model
from utils.pandas import anti_join
from utils.targets import CSVTargetInfo, PickleTargetInfo
from utils.tasks import AutoLoadTask, ExistingFileSL


logger = logging.getLogger('sciluigi-interface')


def save_similar_docs(path, df):
    with pd.ExcelWriter(path, engine='xlsxwriter') as writer:
        sheet_name = '類似文書'
        df.to_excel(writer, sheet_name=sheet_name)
        workbook = writer.book
        worksheet = writer.sheets[sheet_name]
        worksheet.autofilter(0, 0, *df.shape)

        text_col_format = workbook.add_format()
        text_col_format.set_text_wrap()
        num_col_format = workbook.add_format({'num_format': '0.0000'})
        worksheet.freeze_panes(1, 2)

        # トピックベクター(3列目以降)をグループ化
        for i, column in enumerate(df.columns[1:], 2):
            if column.startswith('topic'):
                worksheet.set_column(
                    i, i, None, num_col_format,
                    {'level': 1, 'hidden': True})
            else:
                worksheet.set_column(
                    i, i, None, None,
                    {'collapsed': True})

        for i, column in enumerate(df.columns, 1):
            if column == 'doc' or column.startswith('similar_doc'):
                worksheet.set_column(i, i, 75, text_col_format, {})

        for i, column in enumerate(df.columns, 1):
            if column.startswith('distance'):
                worksheet.set_column(i, i, None, num_col_format)


class SimilarDocs(sl.TargetInfo):
    """類似文章の ExcelFile"""

    def save(self, df):
        save_similar_docs(self.path, df)


class SimilarDocFinder(object):
    """Find similar documents from stored ones."""

    def __init__(
        self,
        docs: np.ndarray,
        topics: np.ndarray,
    ):
        # Construct KDTree based on Hellinger distance.
        self._docs = docs
        self._kdtree = KDTree(np.sqrt(topics))

    @classmethod
    def from_dataframe(cls, df_doc2topic: pd.core.frame.DataFrame):
        return cls(df_doc2topic.index, df_doc2topic.topic)

    def find_similar_docs_from_vector(
        self,
        topic_vector: np.ndarray,
        k: int = 1
    ):
        dist, ind = self._kdtree.query(np.sqrt(topic_vector), k=k)
        return dist, self._docs[ind]

    def find_similar_docs_from_vector_omit_similar_string(
        self,
        topic_vector: np.ndarray,
        k: int = 1,
        doc: str = None,
        threshold: float = 0.5
    ):
        i = 2
        while True:
            dist, ind = self._kdtree.query(
                np.sqrt(topic_vector),
                k=min(k * i, self._docs.shape[0] - 1)
            )
            docs = self._docs[ind]
            edit_distances = np.vectorize(partial(nlevenshtein, doc, method=1))(docs)
            not_similar_string = edit_distances > threshold
            if np.sum(not_similar_string) >= k or (k * i, self._docs.shape[0] - 1):
                break
            i += 1
        return dist[not_similar_string][:k], docs[not_similar_string][:k]


def preprocess_doc_df(
    in_df: pd.core.frame.DataFrame,
    min_doc_length: int,
    ignored_topics: list,
    n_query_docs: int = None,
    seed: int = None,
):
    df_docs = in_df.drop_duplicates()

    df_query_docs = (
        in_df[
            min_doc_length <= in_df.doc.str.len()
        ].reset_index(drop=True)
    )
    if n_query_docs:
        df_query_docs = df_query_docs.sample(n=n_query_docs, random_state=seed)

    if ignored_topics:
        df_docs = df_docs.drop(ignored_topics, axis=1)
        doc_denoms = df_docs.filter(regex=r'topic_[0-9]+', axis=1).sum(axis=1)
        for col in df_docs.columns:
            if not col.startswith('topic_'):
                continue
            df_docs[col] = df_docs[col] / doc_denoms

        df_query_docs = df_query_docs.drop(ignored_topics, axis=1)
        query_denoms = df_query_docs.filter(regex=r'topic_[0-9]+', axis=1).sum(axis=1)
        for col in df_query_docs.columns:
            if not col.startswith('topic_'):
                continue
            df_query_docs[col] = df_query_docs[col] / query_denoms

    return df_docs, df_query_docs


def get_similar_docs(
    df_query_docs,
    df_docs,
    n_top,
):
    """
    """
    if 'group' in df_query_docs.columns:
        group, = df_query_docs.group.drop_duplicates()
        df_docs = df_docs.query('group == @group')
        logger.info(f'Finding similar docs for group {group}.')
    else:
        logger.info('Finding similar docs.')
    df_topics = df_docs.filter(regex=r'topic_[0-9]+', axis=1)
    finder = SimilarDocFinder(
        docs=df_docs.doc.values,
        topics=df_topics.values,
    )
    df_query_topics = df_query_docs.filter(regex=r'topic_[0-9]+', axis=1)

    def find_result_to_data_frame(doc_id, doc, topic_vector, row_num):
        p.update(row_num)
        distance, docs = finder.find_similar_docs_from_vector_omit_similar_string(
            [topic_vector],
            k=n_top,
            doc=doc
        )
        try:
            return pd.DataFrame.from_items((
                ('id', doc_id),
                ('rank', list(range(1, docs.shape[0] + 1))),
                ('similar_doc', docs),
                ('distance', distance)
            ))
        except:
            from ipdb import set_trace; set_trace()
            raise

    p = ProgressBar(maxval=df_query_topics.shape[0]).start()
    df_similar_docs = (
        pd.concat([
            find_result_to_data_frame(doc_id, doc, row, row_num)
            for doc_id, doc, (row_num, row)
            in zip(
                iter(df_query_docs.id),
                iter(df_query_docs.doc),
                df_query_topics.reset_index(drop=True).iterrows()
            )
        ])
        .set_index(['id', 'rank'])
        .stack()
        # .unstack(level=-2)
        # .unstack(level=-1)
        .unstack()
        .reset_index()
    )
    p.finish()
    df_result = df_query_docs[['id', 'doc']].set_index('id').merge(
         df_query_topics.set_index(df_query_docs.id),
         right_index=True,
         left_index=True,
    ).merge(
         df_similar_docs.set_index('id'),
         right_index=True,
         left_index=True,
    )
    return df_result


def get_similar_docs_groupwise(
    df_query_docs: pd.core.frame.DataFrame,
    df_docs: pd.core.frame.DataFrame,
    df_doc_group: pd.core.frame.DataFrame,
    n_top: int,
):
    df_docs = df_docs.merge(
        df_doc_group,
        left_on='id',
        right_on='id',
        how='left'
    )
    df_query_docs = df_query_docs.merge(
        df_doc_group,
        left_on='id',
        right_on='id',
        how='left'
    )
    df_result = (
        df_query_docs
        .groupby('group')
        .apply(get_similar_docs, df_docs, n_top)
    )
    return df_result


class GetSimilarDocs(AutoLoadTask):

    # The number of document to be found.
    n_top = luigi.IntParameter(default=5)
    # The minimum length of the document to get similar documents.
    min_doc_length = luigi.IntParameter(default=300)
    ignored_topics = luigi.ListParameter(default=[])
    grouping_table_path = luigi.Parameter()
    n_query_docs = luigi.IntParameter()
    seed = luigi.Parameter(default=0)

    in_df = None

    @property
    def prefix(self):
        ignored_topics = '_'.join(map(str, self.ignored_topics))
        ignored_topics_str = f'-topic{ignored_topics}_ignored' if ignored_topics else ''
        if self.grouping_table_path:
            grouping_base = path.splitext(path.basename(self.grouping_table_path))[0]
            grouping = f'-group_{grouping_base}'
        else:
            grouping = ''
        return (
            path.splitext(self.in_df().path)[0] +
            f'-top{self.n_top}-min{self.min_doc_length}chars' +
            ignored_topics_str +
            grouping +
            '-similar_docs'
        )

    def out_similar_docs_csv(self):
        return CSVTargetInfo(self, self.prefix + '.csv')

    def out_similar_docs_pkl(self):
        return PickleTargetInfo(self, self.prefix + '.pkl')

    def out_similar_docs_xlsx(self):
        return SimilarDocs(self, self.prefix + '.xlsx')

    def process(self, in_df):
        df_topics, df_query_topics = preprocess_doc_df(
            in_df,
            self.min_doc_length,
            self.ignored_topics,
            self.n_query_docs,
            self.seed,
        )
        if self.grouping_table_path:
            df_grouping = pd.read_csv(
                self.grouping_table_path,
                encoding='utf-16',
                sep='\t'
            )
            df_result = get_similar_docs_groupwise(
                df_query_topics,
                df_topics,
                df_grouping,
                self.n_top,
            )
        else:
            df_result = get_similar_docs(
                df_query_topics,
                df_topics,
                self.n_top,
            )
        logger.info('Writing to files.')
        self.out_similar_docs_csv().save(df_result)
        self.out_similar_docs_pkl().save(df_result)
        self.out_similar_docs_xlsx().save(df_result)


class MeCabParse(sl.Task):

    in_df_pickle = None
    target_column = luigi.Parameter(default=None)

    def out_pickle(self):
        full_path = (
            path.splitext(self.in_df_pickle().path)[0] +
            '_{target_column}_parsed.pkl'.format(target_column=self.target_column))
        return sl.TargetInfo(self, full_path)

    def out_excel(self):
        full_path = (
            path.splitext(self.in_df_pickle().path)[0] +
            '_{target_column}_parsed.xlsx'.format(target_column=self.target_column))
        return sl.TargetInfo(self, full_path)

    def run(self):
        with open(self.in_df_pickle().path, 'rb') as in_f:
            in_df = pickle.load(in_f)

        # セル内改行があるので、改行を削除する。
        target_texts = (
            in_df[self.target_column]
            .str.replace('\r', '')
            .str.replace('\n', '')
            .str.normalize('NFKC')
        )
        df_parse = mecab_parse_texts(target_texts)
        df_parse.to_pickle(self.out_pickle().path)
        df_parse.to_excel(self.out_excel().path, index=None)


class MakePLDAInput(AutoLoadTask):
    """PLDA の入力用ファイルを作る。"""

    in_df = None
    stop_words_path = luigi.Parameter(default=None)

    @property
    def prefix(self):
        return (
            path.splitext(self.in_df().path)[0] +
            ("-stop_words=" + path.basename(self.stop_words_path)
             if self.stop_words_path
             else '')
        )

    def out_word_freq_csv(self):
        full_path = (self.prefix + '_word_freq.csv')
        return CSVTargetInfo(self, full_path)

    def out_doc_word_freq_csv(self):
        full_path = (self.prefix + '_doc_word_freq.txt')
        return CSVTargetInfo(self, full_path)

    def out_doc_word_freq_pickle(self):
        full_path = (self.prefix + '_doc_word_freq.pkl')
        return PickleTargetInfo(self, full_path)

    def process(self, in_df):
        # 前処理、名詞のみにして単語頻度が1以下のものを除外する。
        if self.stop_words_path:
            df_stop_words = pd.read_csv(self.stop_words_path)
        else:
            df_stop_words = None

        df_nouns_frequency, df_doc_word_freq, df_result = shape_plda_input(in_df, df_stop_words)
        self.out_word_freq_csv().save(df_nouns_frequency)
        df_result.to_csv(self.out_doc_word_freq_csv().path, index=False)
        df_doc_word_freq.to_pickle(self.out_doc_word_freq_pickle().path)


class RunPLDA(sl.Task):
    """Run LDA by PLDA

    ./plda/lda --num_topics 30 --alpha 0.6 --beta 0.01 \
    --training_data_file data/interim/FTIR_base_info_JP_4wheels_col_F_FAULT_PROPOSAL_LL_0.4_s0_F_FAULT_PROPOSAL_LL_parsed_doc_word_freq.txt \
    --model_file model.txt --total_iterations 1000 --burn_in_iterations 900"""

    default_hyper_params = dict(
        alpha=0.6,
        beta=0.01,
        num_topics=30,
        total_iterations=1000,
        burn_in_iterations=900,
        random_seed=0,
        compute_likelihood='true',
    )

    in_text = None
    hyper_params = luigi.DictParameter(default={})

    @property
    def actual_hyper_params(self):
        return dict(
            self.default_hyper_params,
            **self.hyper_params
        )

    def out_model_text(self):
        dirname = path.splitext(self.in_text().path)[0]
        try:
            mkdir(dirname)
        except:
            pass
        params_str = '_'.join(
            sorted([
                '{}={}'.format(k, v)
                for k, v
                in self.actual_hyper_params.items()
            ])
        )
        full_path = path.join(
            dirname,
            params_str + '_plda.model')
        return sl.TargetInfo(self, full_path)

    def run(self):
        plda_train(
            self.out_model_text().path,
            self.in_text().path,
            return_result=False,
            **self.actual_hyper_params
        )

def save_topic_word(path, df):
    with pd.ExcelWriter(path, engine='xlsxwriter') as writer:
        sheet_name = 'トピック'
        df.to_excel(writer, sheet_name=sheet_name)
        workbook = writer.book
        worksheet = writer.sheets[sheet_name]
        worksheet.autofilter(0, 0, *df.shape)
        worksheet.freeze_panes(1, 1)

        worksheet.conditional_format(
            1, 1, *df.shape,
            {'type': 'data_bar',
             'bar_solid': True,
             'min_value': 0,
             'max_value': 1,
            }
        )

        num_col_format = workbook.add_format({'num_format': '0.0000'})
        for i, column in enumerate(df.columns, 1):
            if column.startswith('topic'):
                worksheet.set_column(i, i, None, num_col_format)


class TopicWord(sl.TargetInfo):
    """トピック単語の Excel ファイル"""

    def save(self, df):
        save_topic_word(self.path, df)


def save_topic_word_ranking(path, df):
    with pd.ExcelWriter(path, engine='xlsxwriter') as writer:
        sheet_name = 'トピックごとの単語ランキング'
        df.to_excel(writer, sheet_name=sheet_name)
        workbook = writer.book
        worksheet = writer.sheets[sheet_name]
        worksheet.autofilter(0, 0, *df.shape)
        worksheet.freeze_panes(1, 0)

        worksheet.conditional_format(
            1, 1, *df.shape,
            {'type': 'data_bar',
             'bar_solid': True,
             'min_value': 0,
             'max_value': 1,
            }
        )

        num_col_format = workbook.add_format({'num_format': '0.0000'})
        for i, column in enumerate(df.columns, 1):
            if str(column).startswith('topic'):
                worksheet.set_column(i, i, None, num_col_format)

class TopicWordRanking(sl.TargetInfo):
    """トピックごとの単語ランキングの Excel ファイル"""

    def save(self, df):
        save_topic_word_ranking(self.path, df)

def save_doc_topic(path, df):
    with pd.ExcelWriter(path, engine='xlsxwriter') as writer:
        sheet_name = '文書トピック'
        df.to_excel(writer, sheet_name=sheet_name)
        workbook = writer.book
        worksheet = writer.sheets[sheet_name]
        worksheet.autofilter(0, 0, *df.shape)
        worksheet.conditional_format(
            1, 2, *df.shape,
            {'type': 'data_bar',
             'bar_solid': True,
             'min_value': 0,
             'max_value': 1,
            }
        )

        text_col_format = workbook.add_format({'bold': False})
        text_col_format.set_text_wrap()
        text_col_format.set_align('left')
        worksheet.set_column(1, 1, 75, text_col_format)

        num_col_format = workbook.add_format({'num_format': '0.0000'})
        worksheet.freeze_panes(1, 2)
        for i, column in enumerate(df.columns[1:], 2):
            if column.startswith('topic'):
                worksheet.set_column(i, i, None, num_col_format)


class DocTopic(sl.TargetInfo):
    """文書トピックの Excel ファイル"""

    def save(self, df):
        save_doc_topic(self.path, df)


class CalcDocTopic(sl.Task):

    in_docs = None
    in_model = None

    def prefix(self):
        return (
            path.splitext(self.in_df_pickle().path)[0] +
            '-{n_topic}topics-seed{seed}'.format(
                n_topic=self.n_topic,
                seed=self.seed,
            )
        )

    def out_topic_word_csv(self):
        full_path = (
            path.splitext(self.in_model().path)[0] +
            '-topic_words.csv')
        return CSVTargetInfo(self, full_path)

    def out_topic_word_xlsx(self):
        full_path = (
            path.splitext(self.in_model().path)[0] +
            '-topic_words.xlsx')
        return TopicWord(self, full_path)

    def out_topic_word_ranking_csv(self):
        full_path = (
            path.splitext(self.in_model().path)[0] +
            '-topic_words_ranking.csv')
        return CSVTargetInfo(self, full_path)

    def out_topic_word_ranking_xlsx(self):
        full_path = (
            path.splitext(self.in_model().path)[0] +
            '-topic_words_ranking.xlsx')
        return TopicWordRanking(self, full_path)

    def out_doc_topic_csv(self):
        full_path = (
            path.splitext(self.in_model().path)[0] +
            '-doc_topics.csv')
        return CSVTargetInfo(self, full_path)

    def out_doc_topic_xlsx(self):
        full_path = (
            path.splitext(self.in_model().path)[0] +
            '-doc_topics.xlsx')
        return DocTopic(self, full_path)

    def run(self):
        # Output of plda includes spaces and tabs
        df_bow = pd.read_pickle(self.in_docs().path)
        df_bow = df_bow[['id', 'original_text', 'base_form', 'freq']]

        normalized_model_matrix = load_plda_model(self.in_model().path)
        self.out_topic_word_csv().save(normalized_model_matrix)
        self.out_topic_word_xlsx().save(normalized_model_matrix)

        topic_cols = [f'topic_{i}' for i in range(len(normalized_model_matrix.columns))]
        topic_ranking_series = [
            (normalized_model_matrix[col]
             .sort_values(ascending=False)
             .reset_index()
             .rename(columns={'word': f'word_{i}'})
            )
            for i, col
            in enumerate(list(topic_cols))
        ]
        df_topic_ranking = pd.concat(topic_ranking_series, axis=1)
        self.out_topic_word_ranking_csv().save(df_topic_ranking)
        self.out_topic_word_ranking_xlsx().save(df_topic_ranking)
        merged = pd.merge(
            normalized_model_matrix,
            df_bow,
            left_index=True,
            right_on='base_form',
        )

        merged = merged.assign(**{
            col: merged[col] * merged.freq
            for col in topic_cols
        })
        merged = merged.rename(columns={'original_text': 'doc'})
        doc_topic = (
            merged
            .filter(regex=r'id|doc|topic_[0-9]+')
            .groupby(['id', 'doc'])
            .sum()
            .apply(lambda r: r / r.sum(), axis=1)
        )
        self.out_doc_topic_csv().save(doc_topic)
        self.out_doc_topic_xlsx().save(doc_topic)


class TrainGensimLDA(AutoLoadTask):

    in_df = None

    stop_words_path = luigi.Parameter(default='')
    hyper_params = luigi.DictParameter(default={})
    default_hyper_params = {
        'alpha': 'auto',
        'eta': 'auto',
        'num_topics': 60,
        'random_state': 0,
        'passes': 100,
        'gamma_threshold': 1e-3
    }

    def out_model_pickle(self):
        dirname = path.splitext(self.in_df().path)[0]
        try:
            mkdir(dirname)
        except:
            pass
        hyper_params = self.default_hyper_params.copy()
        hyper_params.update(self.hyper_params)
        params_str = (
            f'{hyper_params["num_topics"]}topics_' +
            f'{hash(tuple(hyper_params.items()))}'
        )
        if self.stop_words_path:
            stop_words_path = path.basename(self.stop_words_path)
            params_str += f'_stop-words-path={stop_words_path}'
        full_path = path.join(
            dirname,
            params_str + '_gensim.model')
        return PickleTargetInfo(self, full_path)

    def out_topic_word_csv(self):
        full_path = (
            path.splitext(self.out_model_pickle().path)[0] +
            '-topic_words.csv')
        return CSVTargetInfo(self, full_path)

    def out_topic_word_xlsx(self):
        full_path = (
            path.splitext(self.out_model_pickle().path)[0] +
            '-topic_words.xlsx')
        return TopicWord(self, full_path)

    def out_topic_word_ranking_csv(self):
        full_path = (
            path.splitext(self.out_model_pickle().path)[0] +
            '-topic_words_ranking.csv')
        return CSVTargetInfo(self, full_path)

    def out_topic_word_ranking_xlsx(self):
        full_path = (
            path.splitext(self.out_model_pickle().path)[0] +
            '-topic_words_ranking.xlsx')
        return TopicWordRanking(self, full_path)

    def out_doc_topic_csv(self):
        full_path = (
            path.splitext(self.out_model_pickle().path)[0] +
            '-doc_topics.csv')
        return CSVTargetInfo(self, full_path)

    def out_doc_topic_xlsx(self):
        full_path = (
            path.splitext(self.out_model_pickle().path)[0] +
            '-doc_topics.xlsx')
        return DocTopic(self, full_path)

    def run(self):
        df_parsed = self.in_df().load()
        hyper_params = self.default_hyper_params.copy()
        hyper_params.update(self.hyper_params)
        if self.stop_words_path != '':
            df_stop_words = pd.read_csv(self.stop_words_path)
            df_parsed = df_parsed.pipe(
                anti_join,
                df_stop_words,
                left_on='base_form',
                right_on='word',
            )
        parsed_col = (
            # id と base_form　（基本形） だけ使う
            df_parsed[['id', 'base_form']]
            # NAを削除する(なんか混じるので)
            .dropna()
            # 文書のIDごとにまとめて base_form の list にする
            .groupby('id')
            .base_form
            .apply(list)
        )
        dictionary = corpora.Dictionary(parsed_col)
        corpus = parsed_col.apply(dictionary.doc2bow)
        lm = LdaModel(
            corpus.tolist(),
            id2word=dictionary,
            **hyper_params,
        )
        self.out_model_pickle().save(lm)
        df_docs = df_parsed[['id', 'original_text']].drop_duplicates()
        df_docs.columns = ['id', 'doc']
        colnames = [
                f'topic_{i}'
                for i
                in range(hyper_params['num_topics'])
        ]

        df_doc_topics = pd.concat([
            df_docs.set_index('id'),
            corpus
            .apply(lm.get_document_topics , minimum_probability=0)
            .apply(lambda x: pd.Series(map(itemgetter(1), x)))
            .fillna(0)
            .rename(columns=lambda i: f'topic_{i}')
        ], axis=1)
        self.out_doc_topic_csv().save(df_doc_topics)
        self.out_doc_topic_xlsx().save(df_doc_topics)
        df_topic_words = pd.DataFrame(
            data=lm.get_topics().transpose(),
            index=dictionary.values(),
            columns=colnames
        ).apply(lambda s: s / s.sum())
        self.out_topic_word_csv().save(df_topic_words)
        self.out_topic_word_xlsx().save(df_topic_words)

        df_topic_ranking = pd.DataFrame()
        topics = lm.show_topics(
            formatted=False,
            num_topics=-1,
            num_words=len(dictionary)
        )
        for i, topics in topics:
            df_topic_ranking = df_topic_ranking.assign(**{
                f'word_{i}': list(map(itemgetter(0), topics)),
                f'topic_{i}': list(map(itemgetter(1), topics)),
            })
        self.out_topic_word_ranking_csv().save(df_topic_ranking)
        self.out_topic_word_ranking_xlsx().save(df_topic_ranking)


class Main(sl.WorkflowTask):

    file_path = luigi.Parameter()
    engine = luigi.Parameter()
    stop_words_path = luigi.Parameter(default=None)
    hyper_params = luigi.DictParameter()

    def workflow(self):
        infile = self.new_task(
            'existing_file',
            ExistingFileSL,
            file_path=self.file_path,
            file_format='csv',
        )
        if self.engine == 'plda':
            make_lda_input = self.new_task(
                'make_lda_input',
                MakePLDAInput,
                stop_words_path=self.stop_words_path,
            )
            make_lda_input.in_df = infile.out_file

            train_lda = self.new_task(
                'train_lda',
                RunPLDA,
                hyper_params=dict(self.hyper_params)
            )
            train_lda.in_text = make_lda_input.out_doc_word_freq_csv
            calc_doc_topic = self.new_task(
                'calc_doc_topic',
                CalcDocTopic
            )
            calc_doc_topic.in_docs = make_lda_input.out_doc_word_freq_pickle
            calc_doc_topic.in_model = train_lda.out_model_text
        else:
            calc_doc_topic = self.new_task(
                'train_lda',
                TrainGensimLDA,
                hyper_params=dict(self.hyper_params),
                stop_words_path=self.stop_words_path,
            )
            calc_doc_topic.in_df = infile.out_file

        return calc_doc_topic


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'input_csv_path',
        help='入力文書のCSVへのパス\n入力のCSV は F_ID と DOC (文書本体)' +
        'の二列を持つヘッダーつきのCSVであり、エンコーディングは utf-8である。'
    )
    parser.add_argument('--stop_words_path', default='')
    subparsers = parser.add_subparsers()
    plda_parser = subparsers.add_parser(
        'plda',
        help='トピックモデルの学習に PLDA を利用する。\n'
             'このオプションを利用する際には src ディレクトリと同じ階層に '
             'PLDA のディレクトリを置いておく必要がある。パラメータは PLDA に準拠する。')
    plda_parser.add_argument('--alpha', type=float, default=0.6)
    plda_parser.add_argument('--beta', type=float, default=0.01)
    plda_parser.add_argument('--burn_in_iterations', type=int, default=900)
    plda_parser.add_argument('--likelihood_interval', type=int, default=-1)
    plda_parser.add_argument('--compute_likelihood', default='true')
    plda_parser.add_argument('--num_topics', type=int, default=30)
    plda_parser.add_argument('--min_doc_length', type=int, default=300)
    plda_parser.add_argument('--n_query_docs', type=int, default=100)
    plda_parser.add_argument('--total_iterations', type=int, default=2000)
    plda_parser.add_argument('--progress_file', default=None)
    plda_parser.set_defaults(which='plda')
    gensim_parser = subparsers.add_parser(
        'gensim',
        help='トピックモデルの学習に gensim を利用する。\n'
             'パラメータは gensim.models.LdaModel に準拠する。')
    gensim_parser.add_argument('--num_topics', type=int)
    gensim_parser.add_argument('--chunksize', default=2000, type=int)
    gensim_parser.add_argument('--passes', default=100, type=int)
    gensim_parser.add_argument('--update_every', default=1, type=int)
    gensim_parser.add_argument('--alpha', default='auto')
    gensim_parser.add_argument('--eta', default='auto')
    gensim_parser.add_argument('--decay', default=0.5, type=float)
    gensim_parser.add_argument('--offset', default=1.0, type=float)
    gensim_parser.add_argument('--eval_every', default=10, type=int)
    gensim_parser.add_argument('--iterations', default=50, type=int)
    gensim_parser.add_argument('--gamma_threshold', default=1e-3, type=float)
    gensim_parser.add_argument('--random_state', default=0, type=int)
    gensim_parser.add_argument('--distributed', default=False, type=bool)
    gensim_parser.set_defaults(which='gensim')
    args = parser.parse_args()
    if args.which == 'plda':
        hyper_params = dict(
            alpha=args.alpha,
            beta=args.beta,
            num_topics=args.num_topics,
            total_iterations=args.total_iterations,
            burn_in_iterations=args.burn_in_iterations,
            stop_words_path=args.stop_words_path,
            ignored_topics=args.ignored_topics,
            grouping_table_path=args.grouping_table_path,
            min_doc_length=args.min_doc_length,
            n_query_docs=args.n_query_docs,
            progress_file=args.progress_file,
            likelihood_interval=args.likelihood_interval,
            compute_likelihood=args.compute_likelihood,
       )
    elif args.which == 'gensim':
        hyper_params = dict(
            num_topics=args.num_topics,
            chunksize=args.chunksize,
            passes=args.passes,
            update_every=args.update_every,
            alpha=args.alpha,
            eta=args.eta,
            decay=args.decay,
            offset=args.offset,
            eval_every=args.eval_every,
            iterations=args.iterations,
            gamma_threshold=args.gamma_threshold,
            random_state=args.random_state,
            distributed=args.distributed,
        )
    main_task = Main(
        file_path=args.input_csv_path,
        engine=args.which,
        stop_words_path=args.stop_words_path,
        hyper_params=hyper_params,
    )
    luigi.build(
        tasks=[main_task],
        local_scheduler=True
    )
