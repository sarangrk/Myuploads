'''FTIRデータからTEXT型の列を削除する。

created by Negoro, 2018/4/23

FTIRデータにはTEXT型の列が多く含まれるが、これを Teradata で読み込むのが難しいため、
TEXT　型の列をすべて削除した CSV を作成することにした。
本スクリプトはその実行処理のためである。
'''
import csv
from operator import itemgetter
from os import path


# データの置かれたディレクトリへのパス。
# この下に 'raw' (元データ置き場) と 'interim' (中間データ置き場)がある前提である。
PRJ_ROOT = path.join(path.dirname(path.abspath(__file__)), path.pardir, path.pardir, path.pardir)
DATA_PATH = path.join(PRJ_ROOT, 'data')


def main(
    input_filename=path.join(DATA_PATH, 'raw', 'FTIR_BASE_INFO_DATA_TABLE.csv'),
    output_filename=path.join(DATA_PATH, 'interim', 'FTIR_BASE_INFO_DATA_TABLE_TEXT_COLS_REMOVED.csv'),
    dropped_columns=[
        42, 43, 44, 45,
        49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64,
        67, 68,
        76, 77,
        88, 89, 90, 91, 92, 93, 94, 95, 96,
        140, 141,
        149, 150,
        156, 157,
        193, 194,
        198, 199,
        214, 215,
        223, 224,
        251, 252, 253, 254,
        259, 260,
        265, 266, 267, 268,
        274, 275,
        277, 278,
        280, 281,
        288,
        293,
        299,
    ],
):
    '''CSVから指定された列を削除したものを出力する。

    デフォルト引数で回せば FTIR データから TEXT 列を削除する。

    Arguments
    ---------

    input_filename: str 入力ファイル名
    output_filename: str 出力ファイル名
    dropped_columns: 削除する列の番号(1-origin, Excel から仕様書のコピペで済むように)
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
        reader = csv.reader(line.replace('\0', '') for line in infs)
        writer = csv.writer(outfs, quoting=csv.QUOTE_ALL)
        header = next(reader)

        ## 列の削除処理
        n_cols = len(header)
        kept_poss = list(range(n_cols))
        for i in reversed(dropped_columns):
            kept_poss.remove(i - 1)
        getter = itemgetter(*kept_poss)

        res_header = getter(header)
        res_lines = map(getter, reader)

        ## 出力
        writer.writerow(res_header)
        writer.writerows(
            [cell.replace('"', "'") for cell in line]
            for line
            in res_lines
        )
        org_n_records += 1

    ## 検算
    # とりあえずは列数と行数だけ揃っていることを確認する。
    with open(output_filename, encoding='cp932', newline='\r\n') as infs:
        reader = csv.reader(infs)
        n_records = 0
        n_res_cols = len(res_header)
        for line in reader:
            assert len(line) == n_res_cols
            n_records += 1


if __name__ == '__main__':
    main()
