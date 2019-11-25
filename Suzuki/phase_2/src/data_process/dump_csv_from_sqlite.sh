#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
sqlite3 -header -csv ../../data/interim/suzuki_phase2_db.sqlite3 "select * from tbhaa_all;" > ../../data/interim/warranty_fcok/fcok.csv
sqlite3 -header -csv ../../data/interim/suzuki_phase2_db.sqlite3 "select * from dbhaa_all;" > ../../data/interim/warranty_fcok/warranty.csv