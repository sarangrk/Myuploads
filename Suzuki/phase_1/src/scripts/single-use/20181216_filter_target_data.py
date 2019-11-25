from itertools import starmap
import re
import sys
import os.path as path

import pandas as pd
import numpy as np
from sqlalchemy.sql import and_, func, or_


PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)
DATA_PATH = path.join(PRJ_ROOT, 'data')
sys.path.append(path.join(PRJ_ROOT, 'src'))


from data.db import session_scope
from data.filter import filter_jp_4wheel_data, filter_by_trouble_complaint_code
from data.load import df_from_query
from data.models import FTIRBaseInfo, TYQ0210, TYQ0110
from scripts.get_similar_docs import extract_similar_docs


PARSED_FILE_PATH = path.join(PRJ_ROOT, 'data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen.csv')
OUT_FILE_PATH = path.join('data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen_noise.csv')
NOISE_CODES = ['84', '7V', '7W', '7X', '7Y', '7Z', '8A', '8B', ]


if __name__ == '__main__':

    with session_scope() as session:
        query = session.query(
            FTIRBaseInfo.c.F_ID,
            FTIRBaseInfo.c.F_FAULT_PROPOSAL_LL,
            func.substr(FTIRBaseInfo.c.F_SELLING_MODEL_SIGN, 1, 5).label('F_SELLING_MODEL_SIGN'),
            TYQ0110.c.G_FPCR_ID,
            TYQ0110.c.G_TROUBLE_COMPLAINT_CODE,
            TYQ0110.c.G_CAUSAL_PARTS_NAME_PL,
        )
        query = filter_by_trouble_complaint_code(filter_jp_4wheel_data(query), NOISE_CODES)
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
    df_fpcr_with_size = df_fpcr[
        df_fpcr
        .G_FPCR_ID
        .isin(
            fpcr_count[fpcr_count > 50]
            .to_frame('size')
            .reset_index()['index']
        )
    ]
    df_parsed_noise = df_parsed.merge(
        df_fpcr_with_size,
        left_on='id',
        right_on='F_ID'
    )
    df_parsed_noise.to_csv(OUT_FILE_PATH, encoding='utf-16', sep='\t', index=False)
