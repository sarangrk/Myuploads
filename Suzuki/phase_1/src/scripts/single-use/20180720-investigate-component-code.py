"""部品コード類に関する調査"""
import sys
from os import path

import pandas as pd
from sqlalchemy import func, and_


from data.db import session_scope
from data.filter_jp_data import filter_jp_4wheel_data
from data.models import FTIRBaseInfo, TYQ0110, TYQ0210, TYQ0650


with session_scope() as session:
    query = (
        session.query(TYQ0650.c.G_COMPONENT_CODE, TYQ0650.c.G_COMPONENT_NAME)
        .filter(TYQ0650.c.G_LANGUAGE_CODE == 'ja_JP')
        .distinct(TYQ0650.c.G_COMPONENT_CODE, TYQ0650.c.G_COMPONENT_NAME)
    )
    df_component_code = pd.read_sql(query.statement, query.session.bind)

# FTIRBaseInfo に入っている部品コード
with session_scope() as session:
    query = (
        session
        .query(FTIRBaseInfo.c.F_COMPONENT_CODE, func.count(FTIRBaseInfo.c.F_COMPONENT_CODE))
        .group_by(FTIRBaseInfo.c.F_COMPONENT_CODE)
        .filter(
            and_(
                FTIRBaseInfo.c.F_REPORT_COUNTRY_CODE == 'JP',
                FTIRBaseInfo.c.F_PRODUCT_SPECIFICATION == '1',
            )
        )
    )
    df_component_hist_ftir = pd.read_sql(query.statement, query.session.bind)


with session_scope() as session:
    query = (
        session
        .query(TYQ0110.c.G_COMPONENT_CODE, func.count(TYQ0110.c.G_COMPONENT_CODE))
        .group_by(TYQ0110.c.G_COMPONENT_CODE)
        .join(TYQ0210, TYQ0110.c.G_FPCR_ID == TYQ0210.c.G_FPCR_ID)
        .join(FTIRBaseInfo, FTIRBaseInfo.c.F_ID == TYQ0210.c.G_ID)
        .filter(
            and_(
                FTIRBaseInfo.c.F_REPORT_COUNTRY_CODE == 'JP',
                FTIRBaseInfo.c.F_PRODUCT_SPECIFICATION == '1',
            )
        )
    )
    df_component_hist = pd.read_sql(query.statement, query.session.bind)

df_component_hist_code_ftir = (
    df_component_hist_ftir
    .assign(F_COMPONENT_CODE=df_component_hist_ftir.F_COMPONENT_CODE + '   ')
    .merge(
        df_component_code,
        left_on='F_COMPONENT_CODE',
        right_on='G_COMPONENT_CODE',
        how='left'
    )
)

df_component_hist_code_ftir.to_csv(
    'component_hist_ftir.csv',
    encoding='utf-16',
    sep='\t'
)

df_component_hist_code = df_component_hist.merge(df_component_code, how='left')
df_component_hist_code.to_csv('component_hist.csv', encoding='utf-16', sep='\t')
