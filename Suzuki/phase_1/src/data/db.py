'''DB 接続関連モジュール'''
import inspect
import pathlib
from contextlib import contextmanager
from os import path

import pandas as pd
from sqlalchemy import MetaData, create_engine
from sqlalchemy.orm import sessionmaker

SQLITE_DB_PATH = str(
    pathlib.Path(path.abspath(__file__)).parent.parent.parent /
    'data' /
    'suzuki.db'
)
SQLITE_DB_URI = f'sqlite:///{SQLITE_DB_PATH}'


def get_engine(db_uri=SQLITE_DB_URI):
    '''SQLite の DB に接続する SQLAlchemy のエンジンを取得する。'''
    return create_engine(db_uri)


engine = get_engine(db_uri=SQLITE_DB_URI)
metadata = MetaData()

# configure Session class with desired options
Session = sessionmaker()

# associate it with our custom Session class
Session.configure(bind=engine)


def query_to_df(query):
    return pd.read_sql(query.statement, query.session.bind)


@contextmanager
def session_scope():
    """Provide a transactional scope around a series of operations."""
    session = Session()
    try:
        yield session
        session.commit()
    except:
        session.rollback()
        raise
    finally:
        session.close()
