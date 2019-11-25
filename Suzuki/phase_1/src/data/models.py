'''各テーブルの SQLAlchemy へのマッピング'''
from sqlalchemy import Table

from .db import get_engine, metadata


engine = get_engine()
metadata.reflect(
    engine,
)


FTIRBaseInfo = Table(
    'ftir_base_info',
    metadata,
    autoload=True,
    autoload_with=engine
)

TYQ0110 = Table(
    'TYQ0110',
    metadata,
    autoload=True,
    autoload_with=engine
)

TYQ0120 = Table(
    'TYQ0120',
    metadata,
    autoload=True,
    autoload_with=engine
)

TYQ0160 = Table(
    'TYQ0160',
    metadata,
    autoload=True,
    autoload_with=engine
)

TYQ0210 = Table(
    'TYQ0210',
    metadata,
    autoload=True,
    autoload_with=engine
)

TYQ0220 = Table(
    'TYQ0220',
    metadata,
    autoload=True,
    autoload_with=engine
)

TYQ0650 = Table(
    'TYQ0650',
    metadata,
    autoload=True,
    autoload_with=engine
)

TYQ0810 = Table(
    'TYQ0810',
    metadata,
    autoload=True,
    autoload_with=engine
)
