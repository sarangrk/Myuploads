"""SciLuigi 用の TargetInfo の拡張

保存するファイル形式に応じた `load()` と `save()` メソッドを
実装することで、ファイルの読み書きを抽象化したもの
"""
import json
import pickle
from csv import QUOTE_NONNUMERIC

import luigi
import pandas as pd
from sciluigi import TargetInfo


class JSONTargetInfo(TargetInfo):

    def load(self):
        with open(self.path, 'r') as infs:
            return json.load(infs)

    def save(self, obj):
        with open(self.path, 'w') as outfs:
            json.dump(obj, outfs)


class PickleTargetInfo(TargetInfo):

    def load(self):
        with open(self.path, 'rb') as infs:
            return pickle.load(infs)

    def save(self, obj):
        with open(self.path, 'wb') as outfs:
            pickle.dump(obj, outfs)


class CSVTargetInfo(TargetInfo):

    def __init__(
        self,
        *args,
        read_options=dict(encoding='utf-16', sep='\t'),
        write_options=dict(encoding='utf-16', sep='\t'),
        **kwargs
    ):
        super().__init__(*args, **kwargs)
        self._read_options = read_options
        self._write_options = write_options

    def load(self):
        return pd.read_csv(self.path, **self._read_options)

    def save(self, df):
        df.to_csv(self.path, **self._write_options)


class CSVTarget(luigi.LocalTarget):

    def __init__(
        self,
        *args,
        read_options=dict(encoding='utf-16', sep='\t'),
        write_options=dict(encoding='utf-16', sep='\t', index=False),
        **kwargs
    ):
        super().__init__(*args, **kwargs)
        self._read_options = read_options
        self._write_options = write_options

    def load(self):
        return pd.read_csv(self.path, **self._read_options)

    def save(self, df):
        df.to_csv(self.path, **self._write_options)


class JSONTarget(luigi.LocalTarget):

    def load(self):
        with open(self.path, 'r') as infs:
            return json.load(infs)

    def save(self, obj):
        with open(self.path, 'w') as outfs:
            json.dump(obj, outfs)

class PickleTarget(luigi.LocalTarget):

    def load(self):
        with open(self.path, 'rb') as infs:
            return pickle.load(infs)

    def save(self, obj):
        with open(self.path, 'wb') as outfs:
            pickle.dump(obj, outfs)
