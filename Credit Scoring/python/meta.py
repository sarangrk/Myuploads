#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Meta processing script

Created on Tue May 29 17:40:00 2018

@author: fd186011
"""

import os
import pyodbc
import openpyxl
import logging
import re
import yaml
import tmpl_util
import db_util

with open("config.yml") as ymlfile:
    cfg = yaml.load(ymlfile)
    HOME_DIR = cfg["HOME_DIR"]
    MAIN_DIR = cfg["MAIN_DIR"]
    conn_str = cfg["CONN_STR"]

PYTHON_DIR = os.path.join(MAIN_DIR, "python")
LOG_DIR = os.path.join(MAIN_DIR, "log")
TMPL_DIR = os.path.join(PYTHON_DIR, "sql_templates")
GEN_DIR = os.path.join(PYTHON_DIR, "generated")

# Function for getting an sql file template from the templates directory
def get_sql_template(sql_template_name):
    with open(os.path.join(TMPL_DIR, sql_template_name)) as f:
        sql_template = f.read()        
    return sql_template

# Function for writing a generated sql file to the generated directory
def write_generated_sql(generated_sql_name, txt):
    with open(os.path.join(GEN_DIR, generated_sql_name), "w") as f:
        f.write(txt)        


# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
log_file = os.path.join(LOG_DIR, "python.log")

# Add file handler for logging into file
fh = logging.FileHandler(log_file, mode='w')
fh.setFormatter(formatter)
logger.addHandler(fh)

# Add stream handler for printing messages to console
sh = logging.StreamHandler()
sh.setFormatter(formatter)
logger.addHandler(sh)

os.environ["ODBCSYSINI"] = HOME_DIR
os.environ["ODBCHOME"] = HOME_DIR

# Read from the metadata Excel file
META_FILENAME = "Credit Scoring Metadata.xlsx"
template_file = os.path.join(MAIN_DIR, META_FILENAME)

wb = openpyxl.load_workbook(template_file)
ws_meta = wb.get_sheet_by_name("Meta")
wb.close()

# Get definitions from the metadata Excel file
logger.info("Getting DB name from Excel metadata file")
db_name = tmpl_util.get_value("DB", ws_meta)

logger.info("Getting trans table name from Excel metadata file")
trans_table = tmpl_util.get_value("TRANS TABLE", ws_meta)

logger.info("Getting variable list from Excel metadata file")
variable_list = tmpl_util.get_variables(ws_meta)

logger.info("Getting fine bins list from Excel metadata file")
var_finebins_def = tmpl_util.get_fine_bins(ws_meta)


# Connect to the database
logger.info("Getting DB connection")
conn = pyodbc.connect(conn_str)
cur = conn.cursor()

# Insert to variable table
logger.info("Insert variable list")
db_util.insert_variable_list(cur, db_name, variable_list)

# Convert the bin definitions to labels and case/when statements
logger.info("Converting bin definitions to labels and case/when statements")
var_finebins_labels = {}
var_finebins_when_stmts = {}
for varname, bins in var_finebins_def.items():
    v = variable_list.get(varname)
    if v:
        is_categorical = (v[0] == "CATEGORICAL")
    else:
        is_categorical = False
    label_list, when_stmt_list = tmpl_util.interpret_metabins(bins, is_categorical)
    var_finebins_labels[varname] = label_list
    var_finebins_when_stmts[varname] = when_stmt_list

# Insert to fine bin definitions table
logger.info("Insert fine bin list")
var_finebins_list = {}
for varname in variable_list:
    label_list = var_finebins_labels.get(varname)
    if not label_list:
        # Use the generic fine bin definitions of the data type
        # if the variable's bins are not explicitly defined
        label_list = var_finebins_labels[variable_list[varname][0]]
    var_finebins_list[varname] = label_list

db_util.insert_fine_bins_list(cur, db_name, var_finebins_list)

# Insert to variable case statements table
logger.info("Insert case statement list")
var_case_stmts = {}
for varname in variable_list:
    s = "WHEN a.varname = '{varname}' THEN\n" +\
        "  CASE\n" +\
        "    {when_stmts}\n" +\
        "  END"
    when_list = var_finebins_when_stmts.get(varname)
    if when_list:
        when_stmts = "\n    ".join(when_list)
    else:
        # Use the generic fine bin definitions of the data type
        # if the variable's bins are not explicitly defined
        when_stmts = "\n    ".join(var_finebins_when_stmts[variable_list[varname][0]])
    s = s.format(varname=varname, when_stmts=when_stmts)
    var_case_stmts[varname] = s

db_util.insert_var_case_stmt_list(cur, db_name, var_case_stmts)

ndq_val = {}


#fetch ndq bins from tbl_ndq_counters table
n_dq_bins=db_util.fetch_ndq_bins(cur, db_name)

# Fixed n_dq bins for summarization
#orig n_dq_bins = ["n_dq_1", "n_dq_3", "n_dq_10", "n_dq_20", "n_dq_30", "n_dq_60", "n_dq_90", "n_dq_120"]
#n_dq_bins = ["n_dq_0","n_dq_1", "n_dq_3", "n_dq_10", "n_dq_20", "n_dq_30", "n_dq_60", "n_dq_90", "n_dq_120+"]

# Check variable list if there are any n_dq bins not in the fixed list, add them for summarization
r = re.compile("n_dq_\d+$")
for v in variable_list:
    if r.match(v) and v not in n_dq_bins:
        n_dq_bins.append(v)


logger.info("Generating templates")

# Generate initialization codes
logger.info("Generating 01_init_ddl.sql")
sql = get_sql_template("01_init_ddl.sql")
write_generated_sql("01_init_ddl.sql", sql.format(db_name=db_name))

logger.info("Generating 02_sp_create_account_fine_bins.sql")
sql = get_sql_template("02_sp_create_account_fine_bins.sql")
write_generated_sql("02_sp_create_account_fine_bins.sql", sql.format(db_name=db_name))


# Generate summarization codes
logger.info("Generating 10_summarize.sql")
sql = get_sql_template("10_summarize.sql")

n_dq_x_stmt_list = []
for n_dq_x in n_dq_bins:
    x = n_dq_x.split("_")[2]
#orig code:
#    s = """INSERT INTO japan_dap.tbl_summary(acct_id, year_month, varname, varvalue)
#SELECT acct_id
#      ,year_month
#      ,'{n_dq_x}'
#      ,TO_CHAR(SUM(inc) OVER (PARTITION BY acct_id ORDER BY year_month ROWS UNBOUNDED PRECEDING))
#FROM   (
#           SELECT acct_id
#                 ,year_month
#                 ,CASE
#                      WHEN TO_NUMBER(varvalue) >= {x} THEN 1
#                      ELSE 0
#                  END AS inc
#           FROM   japan_dap.tbl_summary
#           WHERE  varname = 'dq_max'
#       ) t;
#"""
#end of orig code
    
    s = """INSERT INTO japan_dap.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT acct_id
      ,year_month
      ,'{n_dq_x}'
      ,TO_CHAR(SUM(inc) OVER (PARTITION BY acct_id ORDER BY year_month ROWS UNBOUNDED PRECEDING))
FROM   (
       	SELECT 
        		src.acct_id
        		,src.year_month
        		,CASE
        	          WHEN TO_NUMBER(varvalue) BETWEEN NDQ.LOW_VAL AND NDQ.HIGH_VAL THEN 1
        	          ELSE 0
        	   END AS inc
        	FROM   japan_dap.tbl_summary src
        	LEFT JOIN 
        	(
        		SELECT 
        			* 
        		FROM JAPAN_DAP.TBL_NDQ_COUNTERS
        		WHERE DQ_VARNAME = '{n_dq_x}'
        	) NDQ
        	ON 1=1
        	WHERE  src.varname = 'dq_max'
       ) t;
"""

    s = s.format(n_dq_x=n_dq_x, x=x)
    n_dq_x_stmt_list.append(s)

n_dq_x_stmts = "\n".join(n_dq_x_stmt_list)
write_generated_sql("10_summarize.sql", sql.format(db_name=db_name, n_dq_x_stmts=n_dq_x_stmts))


# Generate target generation codes
logger.info("Generating 15_generate_target.sql")
sql = get_sql_template("15_generate_target.sql")
write_generated_sql("15_generate_target.sql", sql.format(db_name=db_name))


# Generate random sampling codes
logger.info("Generating 20_random_sample.sql")
sql = get_sql_template("20_random_sample.sql")
write_generated_sql("20_random_sample.sql", sql.format(db_name=db_name))


# Generate WoE & IV codes
logger.info("Generating 30_calculate_woe_iv.sql")
sql = get_sql_template("30_calculate_woe_iv.sql")

varname_when_stmt_list = []
for varname in variable_list:
    s = "WHEN varname = '{varname}' THEN\n" +\
        "  CASE\n" +\
        "    {when_stmts}\n" +\
        "  END"
    when_list = var_finebins_when_stmts.get(varname)
    if when_list:
        when_stmts = "\n    ".join(when_list)
    else:
        # Use the generic fine bin definitions of the data type
        # if the variable's bins are not explicitly defined
        when_stmts = "\n    ".join(var_finebins_when_stmts[variable_list[varname][0]])
    s = s.format(varname=varname, when_stmts=when_stmts)
    varname_when_stmt_list.append(s)

varname_when_stmts = "\n".join(varname_when_stmt_list)
write_generated_sql("30_calculate_woe_iv.sql", sql.format(db_name=db_name, varname_when_stmts=varname_when_stmts))


# Generate stratified random sampling codes
logger.info("Generating 40_srs.sql")
sql = get_sql_template("40_srs.sql")
write_generated_sql("40_srs.sql", sql.format(db_name=db_name))


# Generate fine binning codes
logger.info("Generating 50_fine_bin.sql")
sql = get_sql_template("50_fine_bin.sql")
write_generated_sql("50_fine_bin.sql", sql.format(db_name=db_name))


# Generate scoring codes
logger.info("Generating 70_score.sql")
sql = get_sql_template("70_score.sql")
write_generated_sql("70_score.sql", sql.format(db_name=db_name, varname_when_stmts=varname_when_stmts))


# Generate monthly iteration codes
logger.info("Generating 90_summarize_iter.sql")
sql = get_sql_template("90_summarize_iter.sql")

n_dq_x_stmt_list = []
for n_dq_x in n_dq_bins:
    x = n_dq_x.split("_")[2]
    s = """INSERT INTO japan_dap.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT t.acct_id
      ,year_month
      ,'{n_dq_x}'
      ,TO_CHAR(t.inc + prev_n)
FROM   (
           SELECT acct_id
                 ,year_month
                 ,CASE
                      WHEN TO_NUMBER(varvalue) >= {x} THEN 1
                      ELSE 0
                  END AS inc
           FROM   japan_dap.tbl_summary
           WHERE  varname = 'dq_max'
           AND    year_month = (SELECT new_year_month FROM japan_dap.tbl_process_new_month)
       ) t
INNER JOIN
       (
           SELECT acct_id
                 ,TO_NUMBER(varvalue) prev_n
           FROM   japan_dap.tbl_summary
                 ,japan_dap.tbl_process_new_month
           WHERE  varname = '{n_dq_x}'
           AND    year_month = CASE
                                   WHEN new_year_month MOD 100 = 1 THEN new_year_month - 100 + 11
                                   ELSE new_year_month - 1
                               END
       ) s
ON     t.acct_id = s.acct_id;
"""
    s = s.format(n_dq_x=n_dq_x, x=x)
    n_dq_x_stmt_list.append(s)

n_dq_x_stmts = "\n".join(n_dq_x_stmt_list)
write_generated_sql("90_summarize_iter.sql", sql.format(db_name=db_name,
                                                        n_dq_x_stmts=n_dq_x_stmts,
                                                        varname_when_stmts=varname_when_stmts))
