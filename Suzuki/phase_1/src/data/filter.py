'''各種フィルタリング用の関数を定義

フェーズ1(2018/04-2018/09)の分析では分析対象を国内四輪に絞ることになったため、
これらの関数を用いる。
'''
from typing import List

import pandas as pd
from sqlalchemy import Numeric, and_, func, cast, or_

from .db import session_scope
from .models import FTIRBaseInfo, TYQ0210, TYQ0110


def filter_jp_4wheel_data(query):
    '''受け取ったクエリを、国内四輪のデータに絞ったクエリに改変する。'''
    return (
        query
        .filter(
            and_(
                FTIRBaseInfo.c.F_REPORT_COUNTRY_CODE == 'JP',
                FTIRBaseInfo.c.F_PRODUCT_SPECIFICATION == '1',
            )
        )
    )


def filter_received(query):
    return (
        query
        .join(TYQ0210, FTIRBaseInfo.c.F_ID == TYQ0210.c.G_ID)
        .filter(TYQ0210.c.G_RECEIVING_JUDGEMENT_CODE == '1')
    )

def filter_newer(query):
    ym = cast(func.substr(FTIRBaseInfo.c.F_ID, 3, 8), Numeric)
    return query.filter(and_(ym >= 200405, ym != 299999))


def drop_routine_inspection(df, col='F_FAULT_PROPOSAL_LL', pattern=r'((点|車)検|年次)'):
    return df[~df[col].str.contains(pattern)]


def drop_similar_str(
    df: pd.core.frame.DataFrame,
    min_distance: float,
    grp_cols: List[str] = ['F_VIN'],
    doc_col: str = 'F_FAULT_PROPOSAL_LL'
):
    from distance import levenshtein
    from itertools import combinations
    from tqdm import tqdm
    tqdm.pandas()

    def _drop(grp):
        if grp.shape[0] == 1:
            return grp
        ids = set(grp.index)
        for id1, id2 in combinations(reversed(sorted(ids)), 2):
            if (id1 not in ids) or (id2 not in ids):
                continue
            str1 = grp[doc_col][id1]
            str2 = grp[doc_col][id2]
            if levenshtein(str1, str2, normalized=True) < min_distance:
                ids.discard(id2)
        return grp[grp.index.isin(ids)]

    return df.groupby(grp_cols, as_index=False).progress_apply(_drop).reset_index(drop=True)


def filter_by_trouble_complaint_code(query, target_codes: List[str]):
    return (
        query
        .join(TYQ0210, FTIRBaseInfo.c.F_ID == TYQ0210.c.G_ID)
        .join(TYQ0110, TYQ0110.c.G_FPCR_ID == TYQ0210.c.G_FPCR_ID)
        .filter(
            and_(
                or_(
                    TYQ0110.c.G_TROUBLE_COMPLAINT_CODE == code
                    for code
                    in target_codes
                )
            )
        )
    )
