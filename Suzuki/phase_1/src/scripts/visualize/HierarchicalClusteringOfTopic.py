import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.cluster.hierarchy import dendrogram, linkage

# topic2word csvのパス
t2w_path = 'trial_2/w2t_trial2.csv'


def extract_lda_info(t2w_path: str) -> str:
    
    """
    Topic2Wordのファイル名からLDAの情報を抽出する。
    
    Arguments:
        t2w_path {str} -- [Topic2Word csvファイルへのpath]
    
    Returns:
        info　{str} -- [Topic2Wordに含まれるLDA情報部分]
    """
    
    info = t2w_path.split(sep='/')[-1][0:-4]
    
    return info


def load_t2w(path: str) -> pd.core.frame.DataFrame:
    
    """
    データロード。
    
    Arguments:
        path {str} -- [Topic2Word csvファイルへのpath]
    
    Returns:
        df {pd.core.frame.DataFrame} -- [Topic2WordのDataFrame]
    """
    
    df = pd.read_csv(t2w_path).rename(columns={'Unnamed: 0': 'word'})
    
    return df


def parse_w2t_df(df: pd.core.frame.DataFrame) -> pd.core.frame.DataFrame:

    """
    確率の正規化して平方根とり、テンドログラムのinputデータを作成する

    Arguments:
        df {pd.core.frame.DataFrame} -- [Topic2WordのDataFrame]
    
    Returns:
        df_dist {pd.core.frame.DataFrame} -- [トピック番号×単語のDataFrame]
    """

    df = df.melt(id_vars='word', var_name='topic_no', value_name='val')
    
    # 正規化準備
    df_sum_val = df.groupby('topic_no', as_index=False)\
    .sum(numeric_only=True)\
    .rename(columns={'val': 'sum_val'})
    
    # トピックが単語を含んでいるか正規化確率計算
    df_norm_org = pd.merge(df, df_sum_val, on='topic_no', how='left')
    df_norm_org['prob'] = df_norm_org['val'] / df_norm_org['sum_val'] # 元のcsvについて、値を縦に足した和が1になるように正規化
    df_norm = df_norm_org.filter(items=['word', 'topic_no', 'prob'])
    
    # トピックと単語のHellinger距離計算
    df_dist = df_norm.assign(
        dist = (df_norm['prob']) ** 0.5,
        topic_no2 = (df_norm.topic_no.str.slice(start=5)).str.zfill(2))\
    .pivot(index='topic_no2', columns='word', values='dist')
    
    return df_dist


if __name__ == "__main__":
    
    info = extract_lda_info(t2w_path)
    df = load_t2w(t2w_path)
    df_dist = parse_w2t_df(df)
    z = linkage(df_dist, 'ward') # 階層クラスタリング実行
    
    plt.figure(figsize=(20, 15))
    plt.title('Dendrogram_' + info)
    plt.xlabel('Topic No')
    plt.ylabel('Distance')
    dendrogram(z)
    plt.savefig('Dendrogram' + info + '.png')
