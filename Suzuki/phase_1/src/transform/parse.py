import itertools
import re
import subprocess
import sys
from multiprocessing import Pool
from os import environ, linesep, mkdir, path
from operator import attrgetter
from typing import Collection, Iterable, Optional

import luigi
import pandas as pd
import sciluigi as sl
import six
from tqdm import tqdm

sys.path.append(path.join(path.dirname(__file__), path.pardir, path.pardir))

from src.utils.targets import CSVTarget


class Subprocess(object):

    def __init__(self, command, encoding='utf-8'):
        subproc_args = {'stdin': subprocess.PIPE, 'stdout': subprocess.PIPE,
                'stderr': subprocess.STDOUT, 'cwd': '.',
                'close_fds': sys.platform != "win32"}
        self.encoding = encoding
        try:
            env = environ.copy()
            if sys.platform == 'win32':
                self.process = subprocess.Popen(command, env=env, shell=True, **subproc_args)
            else:
                self.process = subprocess.Popen('bash -c "%s"' % command, env=env,
                                            shell=True, **subproc_args)
        except OSError:
            raise
        (self.stdouterr, self.stdin) = (self.process.stdout, self.process.stdin)

    def __del__(self):
        self.process.stdin.close()
        try:
            self.process.kill()
            self.process.wait()
        except OSError:
            pass
        except TypeError:
            pass
        except AttributeError:
            pass

    def query(self, sentence, pattern):
        assert(isinstance(sentence, six.text_type))
        self.process.stdin.write(sentence.encode(self.encoding, 'ignore')+linesep.encode(self.encoding))
        self.process.stdin.flush()
        result = ""
        while True:
            line = self.stdouterr.readline()[:-1].decode(self.encoding)
            if re.search(pattern, line):
                break
            result = "%s%s\n" % (result, line)
        return result


def mecab_parse_texts(
    target_texts: pd.core.series.Series,
    ids: Optional[pd.core.series.Series] = None
) -> pd.core.frame.DataFrame:
    # `if ids` だと ValueError が吐かれる
    import MeCab
    _TAGGER = MeCab.Tagger("-Ochasen")
    if ids is not None:
        assert len(target_texts) == len(ids)
    parsed_texts = (
        target_texts
        .apply(_TAGGER.parse)
        .str.split('\n')
        .apply(lambda l: l[:-2])
        .tolist()
    )
    parsed_texts_series = pd.Series(list(itertools.chain.from_iterable(parsed_texts)))
    n_words = list(map(len, parsed_texts))
    positions = pd.Series(list(itertools.chain.from_iterable(map(range, n_words))))
    target_texts_column = pd.Series(
        list(
            itertools.chain.from_iterable(
                itertools.starmap(
                    itertools.repeat,
                    zip(target_texts, n_words)))))
    df_parse = pd.concat(
        [target_texts_column, positions, parsed_texts_series.str.split('\t', expand=True)],
        axis=1)
    df_parse.columns = [
        'original_text',
        'word_position',
        'surface_form',
        'pronunciation',
        'base_form',
        'word_class',
        'inflection_type',
        'inflection_form',
    ]
    if ids is not None:
        id_column = pd.Series(
            list(
                itertools.chain.from_iterable(
                    itertools.starmap(
                        itertools.repeat,
                        zip(ids, n_words)))))
        df_parse = pd.concat([id_column.rename('id'), df_parse], axis=1).set_index(['id', 'word_position'])
    return df_parse


def jumanpp_parse_texts(
    target_texts: Iterable[str],
    ids: Optional[pd.core.series.Series] = None,
    n_process: int = None,
) -> pd.core.frame.DataFrame:
    from pyknp import Jumanpp
    # `if ids` だと ValueError が吐かれる
    from pyknp import Jumanpp
    if ids is not None:
        assert len(target_texts) == len(ids)
    with Pool(n_process) as pool:
        jumanpp = Jumanpp()
        parsed_texts = list(pool.map(jumanpp.analysis, target_texts))
    n_words = list(map(len, parsed_texts))
    positions = pd.Series(list(itertools.chain.from_iterable(map(range, n_words))))
    target_texts_column = pd.Series(
        list(
            itertools.chain.from_iterable(
                itertools.starmap(
                    itertools.repeat,
                    zip(target_texts, n_words)))))
    df_parse = pd.DataFrame.from_records(
        map(
            attrgetter('midasi', 'hinsi', 'bunrui'),
            itertools.chain.from_iterable(
                parsed_texts)),
        columns=['surface_form', 'word_class', 'sub_category'])
    df_parse = pd.concat(
        [target_texts_column, positions, df_parse],
        axis=1)
    if ids is not None:
        id_column = pd.Series(
            list(
                itertools.chain.from_iterable(
                    itertools.starmap(
                        itertools.repeat,
                        zip(ids, n_words)))))
        df_parse = pd.concat([id_column.rename('id'), df_parse], axis=1).set_index(['id', 'word_position'])
    return df_parse


class Chasen(object):
    """chasen を実行するためのインターフェース"""

    def __init__(
        self,
        command=None,
        option='-i w',
        pattern=r'EOS',
    ):
        if sys.platform == 'win32':
            self.encoding = 'cp932'
            self.option = ''
        else:
            self.encoding = 'utf-8'
            self.option = option
        if not command:
            if sys.platform == 'win32':
                self.command = 'C:\Program Files (x86)\chasen21\chasen.exe'
            else:
                self.command = 'chasen'
        else:
            self.command = command
        self.pattern = pattern
        self.subprocess = None

    def parse(self, input_str):
        import re
        if not self.subprocess:
            command = "%s %s" % (self.command, self.option)
            self.subprocess = Subprocess(command, encoding=self.encoding)
        return ''.join(
            self.subprocess.query(sentence, pattern=self.pattern)
            for sentence
            in re.findall('[^。]*。?', input_str)
        )

def chasen_parse_texts(
    target_texts: Collection[str],
    ids: Optional[pd.core.series.Series] = None,
    n_process: int = None,
) -> pd.core.frame.DataFrame:
    # `if ids` だと ValueError が吐かれる
    if ids is not None:
        assert len(target_texts) == len(ids)
    tqdm.pandas()
    parsed_texts = (
        pd.Series(target_texts)
        .progress_apply(Chasen().parse)
        .str.split('\n')
        .apply(lambda l: l[:-1])
        .tolist()
    )
    parsed_texts_series = pd.Series(list(itertools.chain.from_iterable(parsed_texts)))
    n_words = list(map(len, parsed_texts))
    positions = pd.Series(list(itertools.chain.from_iterable(map(range, n_words))))
    target_texts_column = pd.Series(
        list(
            itertools.chain.from_iterable(
                itertools.starmap(
                    itertools.repeat,
                    zip(target_texts, n_words)))))
    df_parse = pd.concat(
        [target_texts_column, positions, parsed_texts_series.str.split('\t', expand=True)],
        axis=1)
    df_parse.columns = [
        'original_text',
        'word_position',
        'surface_form',
        'pronunciation',
        'base_form',
        'word_class',
        'inflection_type',
        'inflection_form',
    ]
    if ids is not None:
        id_column = pd.Series(
            list(
                itertools.chain.from_iterable(
                    itertools.starmap(
                        itertools.repeat,
                        zip(ids, n_words)))))
        df_parse = pd.concat([id_column.rename('id'), df_parse], axis=1).set_index(['id', 'word_position'])
    return df_parse


class ParseDocs(luigi.Task):

    config : dict = {}

    input_cls = luigi.TaskParameter()
    input_params = luigi.DictParameter()
    doc_column_name = luigi.Parameter(default='DOC')
    dir_name = luigi.Parameter()
    engine = luigi.parameter.ChoiceParameter(
        choices=['mecab', 'jumanpp', 'chasen'],
        default='mecab'
    )

    def requires(self):
        yield self.input_cls(config=self.config, **self.input_params)

    def output(self):
        try:
            mkdir(self.dir_name)
        except:
            pass
        full_path = path.join(
            self.dir_name,
            f'parsed_docs_{self.engine}.csv'
        )
        return CSVTarget(full_path)

    def run(self):
        in_df, = [
            target.load()
            for target
            in self.input()
        ]

        # セル内改行があるので、改行を削除する。
        target_texts = (
            in_df[self.doc_column_name]
            .str.replace('\r', '')
            .str.replace('\n', '')
            .str.replace('ｰ', 'ー')
            .str.normalize('NFKC')
        )
        if self.engine == 'mecab':
            df_parse = mecab_parse_texts(target_texts, ids=in_df.F_ID)
        elif self.engine == 'chasen':
            df_parse = chasen_parse_texts(target_texts, ids=in_df.F_ID)
        elif self.engine == 'jumanpp':
            df_parse = jumanpp_parse_texts(target_texts, ids=in_df.F_ID)

        df_parse = df_parse.assign(
            used=df_parse.word_class.str.match('^(名詞[^数]*|未知語)$')
        )
        self.output().save(df_parse.reset_index())
