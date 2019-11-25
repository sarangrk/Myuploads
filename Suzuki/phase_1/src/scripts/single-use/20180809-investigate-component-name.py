"""品番と品名類に関する調査"""
import sys
from os import path

import pandas as pd
from sqlalchemy import func, and_

# %cd /Users/tn250021/Projects/2018/Suzuki/src

from data.db import session_scope
from data.filter_jp_data import filter_jp_4wheel_data
from data.models import FTIRBaseInfo, TYQ0110, TYQ0210, TYQ0650


# FTIRBaseInfo に入っている部品コードを抜き出す
with session_scope() as session:
    query = (
        session
        .query(FTIRBaseInfo.c.F_MAIN_CAUSE_NO, FTIRBaseInfo.c.F_MAIN_CAUSE_NAME_LL, func.count('*'))
        .group_by(FTIRBaseInfo.c.F_MAIN_CAUSE_NO, FTIRBaseInfo.c.F_MAIN_CAUSE_NAME_LL)
        .filter(
            and_(
                FTIRBaseInfo.c.F_REPORT_COUNTRY_CODE == 'JP',
                FTIRBaseInfo.c.F_PRODUCT_SPECIFICATION == '1',
            )
        )
    )
    df_main_cause_ftir = pd.read_sql(query.statement, query.session.bind)

# 部品コードとして重要なのは `-` よりも左側のコードなので、それだけを抜き出して送別集計する。
# 部品名は最頻値を使う
df_main_cause_ftir_2 = (
    df_main_cause_ftir.assign(
        F_MAIN_CAUSE_NO=df_main_cause_ftir
        .F_MAIN_CAUSE_NO
        .str.split('-')
        .str[0].str.strip()
    )
    .groupby(['F_MAIN_CAUSE_NO'])
    .apply(
        lambda df: pd.Series(dict(
            F_MAIN_CAUSE_NAME_LL=df.F_MAIN_CAUSE_NAME_LL[df.count_1.idxmax()],
            count_1=df.count_1.sum()))
    )
    .assign(
        F_MAIN_CAUSE_NAME_LL=lambda df: df.F_MAIN_CAUSE_NAME_LL.str.normalize('NFKC')
    )
)

df_main_cause_ftir.to_csv('main_cause_ftir.csv', encoding='utf-16', sep='\t')
df_main_cause_ftir_2.to_csv('main_cause_upper_category_ftir.csv', encoding='utf-16', sep='\t')


# 以下、FPCR で同様に
with session_scope() as session:
    query = (
        session
        .query(
            TYQ0110.c.G_CAUSAL_PARTS_NO,
            TYQ0110.c.G_CAUSAL_PARTS_NAME_PL,
            func.count('*'))
        .group_by(
            TYQ0110.c.G_CAUSAL_PARTS_NO,
            TYQ0110.c.G_CAUSAL_PARTS_NAME_PL,
            )
        .join(TYQ0210, TYQ0110.c.G_FPCR_ID == TYQ0210.c.G_FPCR_ID)
        .join(FTIRBaseInfo, FTIRBaseInfo.c.F_ID == TYQ0210.c.G_ID)
        .filter(
            and_(
                FTIRBaseInfo.c.F_REPORT_COUNTRY_CODE == 'JP',
                FTIRBaseInfo.c.F_PRODUCT_SPECIFICATION == '1',
            )
        )
    )
    df_main_cause_fpcr = pd.read_sql(query.statement, query.session.bind)

df_main_cause_fpcr
df_main_cause_fpcr.assign(G_CAUSAL_PARTS_NAME_PL=df_main_cause_fpcr.G_CAUSAL_PARTS_NAME_PL.str.normalize('NFKC')).groupby('G_CAUSAL_PARTS_NAME_PL').sum().to_csv('fpcr_name_normalized.csv', encoding='utf-16', sep='\t')


df_main_cause_fpcr_2 = (
    df_main_cause_fpcr.assign(
        G_CAUSAL_PARTS_NO=df_main_cause_fpcr
        .G_CAUSAL_PARTS_NO
        .str.split('-')
        .str[0].str.strip()
    )
    .groupby(['G_CAUSAL_PARTS_NO'])
    .apply(
        lambda df: pd.Series(dict(
            G_CAUSAL_PARTS_NAME_PL=df.G_CAUSAL_PARTS_NAME_PL[df.count_1.idxmax()],
            count_1=df.count_1.sum()))
    )
    .assign(
        G_CAUSAL_PARTS_NAME_PL=lambda df: df.G_CAUSAL_PARTS_NAME_PL.str.normalize('NFKC')
    )
)

df_main_cause_fpcr.to_csv('main_cause_fpcr.csv', encoding='utf-16', sep='\t')
df_main_cause_fpcr_2.to_csv('main_cause_upper_category_fpcr.csv', encoding='utf-16', sep='\t')