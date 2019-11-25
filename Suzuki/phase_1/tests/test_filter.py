from collections import OrderedDict

import pandas as pd

from data.filter import drop_similar_str


def test_drop_similar_str():
    df_org = pd.DataFrame(OrderedDict([
        ('grp', [0, 0, 0, 0, 1, 1, 1]),
        ('text', [
            'abcde',
            'abcdc',
            'abcdd',
            'fghij',
            'abcde',
            'fghij',
            'klmno',
        ]),
        ('kept', 0),
    ]))
    df_exp_1 = pd.DataFrame(OrderedDict([
        ('grp', [0, 0, 1, 1, 1]),
        ('text', [
            'abcdd',
            'fghij',
            'abcde',
            'fghij',
            'klmno',
        ]),
        ('kept', 0),
    ]))
    df_act_1 = drop_similar_str(
        df_org,
        0.25,
        grp_cols=['grp'],
        doc_col='text',
    )
    pd.testing.assert_frame_equal(df_act_1, df_exp_1)
    df_act_2 = drop_similar_str(
        df_org,
        0.2,
        grp_cols=['grp'],
        doc_col='text',
    )
    pd.testing.assert_frame_equal(df_act_2, df_org)
