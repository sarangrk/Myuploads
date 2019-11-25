"""異音系のデータの定義が変わったので、再度抽出処理を流す。


以下、小沢さんのメールから引用

```
●異音の対象の現象コードについて

0D ベルト鳴き
2E ギヤ音
2F ギヤ鳴り
R3 ワイパビビリ
3G 雑音（ノイズ）
43 ブレーキ鳴き
84 異音／騒音
7V メカニカルノイズ
7W びびり音／がたつき音（ラトル音）
7X きしみ音／こすれ音
7Y 打音（ノック音）／干渉音
7Z 風切音／笛吹き音
8A こもり音
8B 吸排気音異常

●案件の装置のサブ区分　「振動・騒音」について

TYQ0110.G_EQUIPMENT_NVH_CODE = 'A0'            //振動・騒音

```
"""
from itertools import starmap
import re
import sys
import os.path as path
import pathlib

import pandas as pd
import numpy as np
from sqlalchemy.sql import and_, func, or_


PRJ_ROOT = pathlib.Path(__file__).absolute().parent.parent.parent.parent
DATA_PATH = path.join(PRJ_ROOT, 'data')
sys.path.append(path.join(PRJ_ROOT, 'src'))


from data.db import session_scope
from data.filter import filter_jp_4wheel_data, filter_by_trouble_complaint_code
from data.load import df_from_query
from data.models import FTIRBaseInfo, TYQ0210, TYQ0110
# from scripts.get_similar_docs import extract_similar_docs


PARSED_FILE_PATH = path.join(str(PRJ_ROOT), r"data\interim\cleansed-text-joined_8764762445972550576\filtered-parsed_docs_chasen.csv")
OUT_FILE_PATH = path.join('data/interim/noise_records_rev.csv')
NOISE_CODES = [
    '0D', '2E', '2F', 'R3', '3G',
    '43', '84', '7V', '7W', '7X',
    '7Y', '7Z', '8A', '8B',
]

if __name__ == '__main__':

    with session_scope() as session:
        query = session.query(
            FTIRBaseInfo.c.F_ID,
            FTIRBaseInfo.c.F_FAULT_PROPOSAL_LL,
            func.substr(FTIRBaseInfo.c.F_SELLING_MODEL_SIGN, 1, 5).label('F_SELLING_MODEL_SIGN'),
            TYQ0110.c.G_FPCR_ID,
            TYQ0110.c.G_TROUBLE_COMPLAINT_CODE,
            TYQ0110.c.G_CAUSAL_PARTS_NAME_PL,
            TYQ0110.c.G_EQUIPMENT_NVH_CODE,
        )
        query = query.filter(
            and_(
                FTIRBaseInfo.c.F_ID == TYQ0210.c.G_ID,
                TYQ0110.c.G_FPCR_ID == TYQ0210.c.G_FPCR_ID
            )
        )
        query = query.filter(
            or_(TYQ0110.c.G_EQUIPMENT_NVH_CODE == 'A0',
                *[TYQ0110.c.G_TROUBLE_COMPLAINT_CODE == code
                  for code
                  in NOISE_CODES
                ]
            )
        )
        query = filter_jp_4wheel_data(query)
        df_fpcr = df_from_query(query)

    df_parsed = pd.read_csv(
        PARSED_FILE_PATH,
        encoding='utf-16',
        sep='\t'
    )
    fpcr_count = (
        df_fpcr[df_fpcr.F_ID.isin(df_parsed.id)]
        .G_FPCR_ID
        .value_counts()
    )
    # df_fpcr_with_size = df_fpcr[
    #     df_fpcr
    #     .G_FPCR_ID
    #     .isin(
    #         fpcr_count[fpcr_count > 50]
    #         .to_frame('size')
    #         .reset_index()['index']
    #     )
    # ]
    df_parsed_noise = df_parsed.merge(
        df_fpcr,
        left_on='id',
        right_on='F_ID'
    )
    df_parsed_noise.to_csv(OUT_FILE_PATH, encoding='utf-16', sep='\t', index=False)
