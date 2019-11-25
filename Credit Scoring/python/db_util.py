#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DB Utility Functions

Created on Mon Jun 18 14:47:36 2018

@author: fd186011
"""

def insert_variable_list(cur, db_name, variable_list):
    values = []
    for var, (datatype, priority) in variable_list.items():
        values.append((var, datatype, priority))

    cur.execute("DELETE FROM {db_name}.tbl_variable ALL".format(db_name=db_name))
    cur.executemany("INSERT INTO {db_name}.tbl_variable VALUES (?, ?, ?)".format(db_name=db_name), values)
    cur.commit()


def insert_fine_bins_list(cur, db_name, var_finebins_list):
    values = []
    for varname, label_list in var_finebins_list.items():
        for i, label in enumerate(label_list):
            values.append((varname, i-2, label.format(varname=varname)))

    cur.execute("DELETE FROM {db_name}.tbl_var_fine_bins ALL".format(db_name=db_name))    
    cur.executemany("INSERT INTO {db_name}.tbl_var_fine_bins VALUES (?, ?, ?)".format(db_name=db_name), values)
    cur.commit()


def insert_var_case_stmt_list(cur, db_name, var_case_stmts):
    values = []
    for var, case_stmt in var_case_stmts.items():
        values.append((var, case_stmt))
        
    cur.execute("DELETE FROM {db_name}.tbl_var_case_stmt ALL".format(db_name=db_name))
    cur.executemany("INSERT INTO {db_name}.tbl_var_case_stmt VALUES (?, ?)".format(db_name=db_name), values)
    cur.commit()
	
def fetch_ndq_bins(cur, db_name):
	ndq_list=[]
	ndq_val = cur.execute("SELECT cast(trim(dq_varname) as varchar(50)) as dq_varname FROM {db_name}.tbl_ndq_counters order by low_val;".format(db_name=db_name))

	for row in ndq_val:
		ndq_list.append(row.dq_varname)
	return ndq_list
	
	