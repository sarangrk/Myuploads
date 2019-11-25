import pickle
import sys
import os.path as path


PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)
DATA_PATH = path.join(PRJ_ROOT, 'data')

sys.path.append(PRJ_ROOT)

from src.data.filter_jp_data import load_jp_4wheel_data
from src.transform.parse import jumanpp_parse_texts

FILE_PATH = path.join(DATA_PATH, 'interim', 'FTIR_base_info_JP_4wheels_col_F_FAULT_PROPOSAL_LL_0.4_s0.pkl')
OUT_FILE_PATH = path.join(DATA_PATH, 'interim', 'FTIR_base_info_JP_4wheels_col_F_FAULT_PROPOSAL_LL_0.4_s0-jumanpp-parse.csv')


if __name__ == '__main__':

    with open(FILE_PATH, 'rb') as infs:
        df_input = pickle.load(infs)

    df_input_sample = df_input.sample(frac=0.001)

    df_input_sample.shape

    out_df = jumanpp_parse_texts(df_input.F_FAULT_PROPOSAL_LL)

    out_df.to_csv(OUT_FILE_PATH)
