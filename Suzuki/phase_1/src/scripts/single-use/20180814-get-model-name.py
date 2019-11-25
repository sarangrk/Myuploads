import pandas as pd

from data.db import session_scope
from data.models import TYQ0810


with session_scope() as session:
    query = (
        session
        .query(TYQ0810.c.G_PRDCT_MODEL, TYQ0810.c.G_KISYU)
        .group_by(TYQ0810.c.G_PRDCT_MODEL, TYQ0810.c.G_KISYU)
    )
    df_model_name = pd.read_sql(query.statement, query.session.bind)

df_model_name
