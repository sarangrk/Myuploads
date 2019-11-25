"""FTIR ID に紐づく機種記号を取り出すスクリプト

とりあえず F_SELLING_MODEL_SIGN を使う。
"""
import sys
from os import path

import pandas as pd
from sqlalchemy import func, and_


from src.data.db import session_scope
from src.data.filter_jp_data import filter_jp_4wheel_data
from src.data.models import FTIRBaseInfo, TYQ0110, TYQ0210, TYQ0650


PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)
DATA_PATH = path.join(PRJ_ROOT, 'data')
PATH = path.join(DATA_PATH, "interim/F_ID-F_SELLING_MODEL_SIGN.csv")


def extract_data():
    with session_scope() as session:
        query = (
            session
            .query(
                FTIRBaseInfo.c.F_ID,
                FTIRBaseInfo.c.F_SELLING_MODEL_SIGN,
                TYQ0210.c.G_PRODUCT_MODEL_CODE,
                TYQ0210.c.G_SALES_MODEL_CODE,
            )
            .filter(
                and_(
                    FTIRBaseInfo.c.F_REPORT_COUNTRY_CODE == 'JP',
                    FTIRBaseInfo.c.F_PRODUCT_SPECIFICATION == '1',
                    FTIRBaseInfo.c.F_ID == TYQ0210.c.G_ID,
                )
            )
        )
        df = pd.read_sql(query.statement, query.session.bind)
    return pd.DataFrame.from_items(
        (('id', df.F_ID),
         ('group', df.F_SELLING_MODEL_SIGN.str.split('-', 1).str[0]))
    )


def main():
    df_result = extract_data()
    df_result.to_csv(PATH, encoding='utf-16', sep='\t', index=False)


if __name__ == '__main__':
    main()
