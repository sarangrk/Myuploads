#!/bin/bash
# テーブルを SQLite にロードするためのスクリプト
# TODO パスを変更する！
cd data

# FTIR_BASE_INFO
iconv -f cp932 -t utf-8 -c raw/FTIR_BASE_INFO_DATA_TABLE.csv > interim/FTIR_BASE_INFO_DATA_TABLE_UTF8_ONLY.csv
sqlite3 suzuki.db "DROP TABLE IF EXISTS FTIR_BASE_INFO"
sqlite3 -separator , suzuki.db ".import interim/FTIR_BASE_INFO_DATA_TABLE_UTF8_ONLY.csv ftir_base_info"

# TYQ0110
iconv -f cp932 -t utf-8 -c raw/TYQ0110_DATA_TABLE.csv > interim/TYQ0110_DATA_TABLE_UTF8_ONLY.csv
sqlite3 suzuki.db "DROP TABLE IF EXISTS TYQ0110"
sqlite3 -separator , suzuki.db ".import interim/TYQ0110_DATA_TABLE_UTF8_ONLY.csv TYQ0110"

# TYQ0120
iconv -f cp932 -t utf-8 -c raw/TYQ0120_DATA_TABLE.csv > interim/TYQ0120_DATA_TABLE_UTF8_ONLY.csv
sqlite3 suzuki.db "DROP TABLE IF EXISTS TYQ0120"
sqlite3 -separator , suzuki.db ".import interim/TYQ0120_DATA_TABLE_UTF8_ONLY.csv TYQ0120"

# TYQ0160
iconv -f cp932 -t utf-8 -c raw/TYQ0160_DATA_TABLE.csv > interim/TYQ0160_DATA_TABLE_UTF8_ONLY.csv
sqlite3 suzuki.db "DROP TABLE IF EXISTS TYQ0160"
sqlite3 -separator , suzuki.db ".import interim/TYQ0160_DATA_TABLE_UTF8_ONLY.csv TYQ0160"

# TYQ0210
iconv -f cp932 -t utf-8 -c raw/TYQ0210_DATA_TABLE.csv > interim/TYQ0210_DATA_TABLE_UTF8_ONLY.csv
sqlite3 suzuki.db "DROP TABLE IF EXISTS TYQ0210"
sqlite3 -separator , suzuki.db ".import interim/TYQ0210_DATA_TABLE_UTF8_ONLY.csv TYQ0210"

# TYQ0220
iconv -f cp932 -t utf-8 -c raw/TYQ0220_DATA_TABLE.csv > interim/TYQ0220_DATA_TABLE_UTF8_ONLY.csv
sqlite3 suzuki.db "DROP TABLE IF EXISTS TYQ0220"
sqlite3 -separator , suzuki.db ".import interim/TYQ0220_DATA_TABLE_UTF8_ONLY.csv TYQ0220"

# TYQ0650
iconv -f cp932 -t utf-8 -c raw/TYQ0650_DATA_TABLE.csv > interim/TYQ0650_DATA_TABLE_UTF8_ONLY.csv
sqlite3 suzuki.db "DROP TABLE IF EXISTS TYQ0650"
sqlite3 -separator , suzuki.db ".import interim/TYQ0650_DATA_TABLE_UTF8_ONLY.csv TYQ0650"

# TYQ0810
iconv -f cp932 -t utf-8 -c raw/TYQ0810_DATA_TABLE.csv > interim/TYQ0810_DATA_TABLE_UTF8_ONLY.csv
sqlite3 suzuki.db "DROP TABLE IF EXISTS TYQ0810"
sqlite3 -separator , suzuki.db ".import interim/TYQ0810_DATA_TABLE_UTF8_ONLY.csv TYQ0810"

cd -
