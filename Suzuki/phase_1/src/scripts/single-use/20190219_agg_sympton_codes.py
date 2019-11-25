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


PARSED_FILE_PATH = path.join(PRJ_ROOT, 'data/interim/cleansed-text-joined_F_FAULT_PROPOSAL_LL-F_FAULT_WHEN_LL-F_FAULT_SITUATION_LL.csv')
OUT_FILE_PATH = path.join(PRJ_ROOT, 'reports/sym_codes.csv')


if __name__ == '__main__':

    df_parsed = pd.read_csv(
        PARSED_FILE_PATH,
        encoding='utf-16',
        sep='\t'
    )
    with session_scope() as session:
        query = filter_jp_4wheel_data(
            session
            .query(
                FTIRBaseInfo.c.F_ID,
                TYQ0110.c.G_FPCR_ID,
                TYQ0110.c.G_TROUBLE_COMPLAINT_CODE
            )
            .join(TYQ0210, FTIRBaseInfo.c.F_ID == TYQ0210.c.G_ID)
            .join(TYQ0110, TYQ0110.c.G_FPCR_ID == TYQ0210.c.G_FPCR_ID)
        )
        df_fpcr = df_from_query(query)
    fpcr_count = (
        df_fpcr[df_fpcr.F_ID.isin(df_parsed.F_ID)]
        .groupby('G_TROUBLE_COMPLAINT_CODE')
        .size()
        .to_frame('n')
        .reset_index()
    )
    fpcr_count.to_csv(OUT_FILE_PATH, encoding='utf-16', sep='\t', index=False)
