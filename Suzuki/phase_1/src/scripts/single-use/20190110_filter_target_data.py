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
OUT_FILE_PATH = path.join(PRJ_ROOT, 'data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/filtered-parsed_docs_chasen_noise_parts_count.csv')
OUT_TARGET_FILE_PATH = path.join(PRJ_ROOT, 'data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/F_ID_parts.csv')
OUT_PARTS_NAME_FILE_PATH = path.join(PRJ_ROOT, 'data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL/parts_names.csv')
NOISE_CODES = ['84', '7V', '7W', '7X', '7Y', '7Z', '8A', '8B', ]


def main():
    with session_scope() as session:
        query = session.query(
            FTIRBaseInfo.c.F_ID,
            FTIRBaseInfo.c.F_FAULT_PROPOSAL_LL,
            func.substr(FTIRBaseInfo.c.F_SELLING_MODEL_SIGN, 1, 5).label('F_SELLING_MODEL_SIGN'),
            TYQ0110.c.G_FPCR_ID,
            TYQ0110.c.G_TROUBLE_COMPLAINT_CODE,
            func.substr(TYQ0110.c.G_CAUSAL_PARTS_NO, 1, 5).label('G_CAUSAL_PARTS_NO'),
            TYQ0110.c.G_CAUSAL_PARTS_NAME_PL,
        )
        query = filter_by_trouble_complaint_code(filter_jp_4wheel_data(query), NOISE_CODES)
        df_fpcr = df_from_query(query)
    df_parsed = pd.read_csv(
        PARSED_FILE_PATH,
        encoding='utf-16',
        sep='\t'
    )
    parts_count = (
        df_fpcr[df_fpcr.F_ID.isin(df_parsed.id)]
        .G_CAUSAL_PARTS_NO
        .value_counts()
        .to_frame('count')
        .reset_index()
    )
    parts_count.columns = ['G_CAUSAL_PARTS_NO', 'count']
    df_parts_names_count = (
        df_fpcr
        .assign(
            G_CAUSAL_PARTS_NAME_PL=df_fpcr.G_CAUSAL_PARTS_NAME_PL.str.strip().str.normalize('NFKC')
        )
        .query('G_CAUSAL_PARTS_NAME_PL != ""')
        .groupby(['G_CAUSAL_PARTS_NO', 'G_CAUSAL_PARTS_NAME_PL'])
        .size()
        .to_frame('size')
        .reset_index()
    )
    df_parts_name = (
        df_parts_names_count
        .loc[df_parts_names_count.groupby('G_CAUSAL_PARTS_NO')['size'].idxmax()]
        .assign(G_CAUSAL_PARTS_NAME_PL=lambda df:df.G_CAUSAL_PARTS_NAME_PL.str.normalize('NFKC'))
    )
    df_fpcr_with_size = (
        df_fpcr
        .drop('G_CAUSAL_PARTS_NAME_PL', axis=1)
        .merge(df_parts_name.drop('size', axis=1))
        .merge(parts_count)
    )
    df_parsed_noise = df_parsed.merge(
        df_fpcr,
        left_on='id',
        right_on='F_ID'
    )
    df_parsed_noise.to_csv(OUT_FILE_PATH, encoding='utf-16', sep='\t', index=False)
    df_parts_name.merge(parts_count).to_csv(OUT_PARTS_NAME_FILE_PATH, encoding='utf-16', sep='\t', index=False)
    (
        df_fpcr_with_size
        .query('count >= 50')
        .assign(
            parts=lambda df: df.G_CAUSAL_PARTS_NO + ' - ' + df.G_CAUSAL_PARTS_NAME_PL
        )[['F_ID', 'parts']]
        .to_csv(OUT_TARGET_FILE_PATH, encoding='utf-16', sep='\t', index=False)
    )


if __name__ == "__main__":
    main()
