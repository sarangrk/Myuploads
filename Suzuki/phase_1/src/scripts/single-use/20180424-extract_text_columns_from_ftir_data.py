'''FTIRデータからTEXT型の列を抽出する。

created by Negoro, 2018/4/24

4/23 の作業とは逆に、TEXT　型の列を抽出した CSV を作成することにした。
本スクリプトはその実行処理のためのものである。
'''
import csv
from os import path
from typing import List


# データの置かれたディレクトリへのパス。
# この下に 'raw' (元データ置き場) と 'interim' (中間データ置き場)がある前提である。
PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)
DATA_PATH = path.join(PRJ_ROOT, 'data')


def extract_fields(
    input_filename: str = path.join(DATA_PATH, 'raw', 'FTIR_BASE_INFO_DATA_TABLE.csv'),
    output_filename: str = path.join(DATA_PATH, 'interim', 'FTIR_BASE_INFO_DATA_TABLE_TEXT_COLS.csv'),
    field_names: List[str] = [],
) -> None:
    '''CSVから指定された列を抽出したものを出力する。

    Arguments
    ---------

    input_filename: 入力ファイル名
    output_filename: 出力ファイル名
    field_names: 抽出する列名のリスト
    '''
    org_n_records = 0
    # Windows 向けのファイルなのでエンコーディングをよしなに変更する。
    # 行末は '' にする(csv.reader / writer の仕様に合わせる。
    with open(input_filename, 'r', encoding='cp932', newline='') as infs, \
         open(output_filename, 'w', encoding='cp932', newline='') as outfs:
        ## 入力
        # FTIR の受領データには NUL　バイトが含まれている(おそらく NULL のフィールドを示している)。
        # csv モジュールではNULバイトが含まれているとエラーが起きるので空文字に置換する。
        # もしかすると問題が起きるかもしれないが、おそらく大丈夫だろう。
        set_field_names = set(field_names)
        reader = csv.DictReader(line.replace('\0', '') for line in infs)
        writer = csv.DictWriter(outfs, field_names, quoting=csv.QUOTE_ALL)

        ## 出力
        writer.writeheader()
        writer.writerows(
            {
                k: v.replace('"', "'")
                for k, v
                in line.items()
                if k in set_field_names
            }
            for line
            in reader
        )
        org_n_records += 1

    ## 検算
    # とりあえずは列数と行数だけ揃っていることを確認する。
    with open(output_filename, encoding='cp932', newline='\r\n') as infs:
        reader = csv.DictReader(infs)
        n_records = 0
        for line in reader:
            assert list(line.keys()) == field_names
            n_records += 1


if __name__ == '__main__':
    extract_fields(
        field_names=[
            "F_ID",
            "F_ID_ROOT",
            "F_ID_ORIGINAL",
            "F_FAULT_SUBJECT",
            "F_FAULT_SUBJECT_LL",
            "F_FAULT_PROPOSAL",
            "F_FAULT_PROPOSAL_LL",
            "F_FEEDBACK",
            "F_FEEDBACK_LL",
        ],
        output_filename=path.join(DATA_PATH, 'interim', 'FTIR_BASE_INFO_DATA_TABLE_TEXT_COLS_1.csv'),
    )
    extract_fields(
        field_names=[
            "F_ID",
            "F_ID_ROOT",
            "F_ID_ORIGINAL",
            "F_UPDATE_LOG",
            "F_FAILURE_INDEX",

        ],
        output_filename=path.join(DATA_PATH, 'interim', 'FTIR_BASE_INFO_DATA_TABLE_TEXT_COLS_2.csv'),
    )
