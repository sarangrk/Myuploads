# suzuki_analytics

このディレクトリにはスズキ様の分析案件のためのデータ・ソースコード類を納めています。

## ディレクトリ構成の概要

ディレクトリは以下の構成になっています。

```
analytics
├── data
├── plda
├── src
└── tests

```

## スクリプトの実行方法

スクリプトの実行方法について述べます。


### 前処理

```
python3 cleansing.py
```

### トピックモデルの作成 & 文書トピックの計算

```
python3 src/scripts/make_lda_model.py --parsed data/interim/FTIR_base_info_JP_4wheels_col_F_ID-F_FAULT_PROPOSAL_LL_0.4_s0-rep_hyph_parsed.csv --num_topics 50
```


## 環境設定(復旧用)

以下は何らかの理由で元データや途中計算結果が消失した場合の復旧用です。

問題なく動いているということであれば、すでに実行済みです。

### レポジトリのコピー

ファイルを展開してください。

### Python のセットアップ

```
sudo apt install python python3-pip
```

### R のセットアップ

```
sudo apt install r-base r-base-core libcurl-openssl-dev libssl-dev libxml2-dev
R -e  'install.packages(c("dplyr", "httr", "purrr", "rvest", "readr", "stringr", "tidyr"))'
```

### PLDA のビルド

```
sudo apt install make gcc g++ mpich
pwd
# /home/ubuntu/suzuki_analytics/plda
make
```
ビルドに失敗する場合、Makefile を編集して コマンドラインオプションに -std=c++98 をつける。

### 形態素解析エンジンのインストール

```
sudo add-apt-repository universe
sudo apt update
sudo apt install chasen mecab libmecab-dev
```

libmecab-dev を入れないと mecab-python3 をインストールできない

### データの DB へのロード

実行のために、 SQLIte のテーブルにロードする必要があります。（実行済み）

0.sqlite3 のインストール

```
sudo apt install sqlite3
```

1.data/raw ディレクトリ以下に以下の生データを置く。

データはそれぞれのテーブルの内容のダンプされたものです。

  - FTIR_BASE_INFO_DATA_TABLE.csv
  - TYQ0110_DATA_TABLE.csv
  - TYQ0120_DATA_TABLE.csv
  - TYQ0160_DATA_TABLE.csv
  - TYQ0210_DATA_TABLE.csv
  - TYQ0220_DATA_TABLE.csv
  - TYQ0650_DATA_TABLE.csv
  - TYQ0810_DATA_TABLE.csv


2.ロード用のスクリプトを実行する。

```bash
$ sh src/data/load_table.sh
$ sqlite3 src/data/create_index.sql
```

### 入力データの分かち書き

20180709-chasen-parse.py を使う。