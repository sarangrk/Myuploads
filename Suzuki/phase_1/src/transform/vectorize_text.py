from typing import Tuple

import luigi
from pandas.core.frame import DataFrame

from .parse import chasen_parse_texts
from .plda import infer


def plda_topicalize(
    text: str,
    df_model: DataFrame,
) -> Tuple[DataFrame, DataFrame]:
    df_parsed = (
        chasen_parse_texts([text])
        .assign(
            used=lambda df: df.word_class.str.match(r'^(名詞[^数]*|未知語)$')
        )
    )
    # ad hoc な処理
    df_parsed = df_parsed.assign(id=0)

    df_topic = infer(df_model, df_parsed)
    return df_parsed, df_topic


class EmbedDocs(luigi.Task):

    input_cls = luigi.TaskParameter()
    input_params = luigi.DictParameter()

    method = luigi.ChoiceParameter(choices=(
        'lda_plda',
        'lda_gensim',
        'doc2vec_gensim',
    ))

    def requires(self):
        yield self.input_cls(cnofig=self.config, **self.input_params)


    def run(self):
        df_input = self.input()[0].load()
        if self.method == 'plda_lda'

        df_parsed_sample = df_parsed.merge(df_parsed[['id']].drop_duplicates().sample(frac=0.01, random_state=0))
        word_lists = df_parsed_sample.groupby('id').base_form.apply(list)
        docs = list(starmap(TaggedDocument, zip(word_lists.tolist(), map(lambda x: [x], list(word_lists.keys())))))

        model = Doc2Vec(docs, vector_size=300, window=3, negative=1, min_count=5, workers=7, epochs=1000)

