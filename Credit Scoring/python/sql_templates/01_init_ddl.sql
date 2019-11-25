DROP TABLE {db_name}.tbl_variable;

CREATE MULTISET TABLE {db_name}.tbl_variable
(
    varname     VARCHAR(30)
   ,datatype    VARCHAR(30)
   ,priority    BYTEINT
)
PRIMARY INDEX(varname);


DROP TABLE {db_name}.tbl_var_fine_bins;

CREATE MULTISET TABLE {db_name}.tbl_var_fine_bins
(
    varname     VARCHAR(30)
   ,bin_id      BYTEINT
   ,label       VARCHAR(100)
)
PRIMARY INDEX(varname);


DROP TABLE {db_name}.tbl_var_case_stmt;

CREATE MULTISET TABLE {db_name}.tbl_var_case_stmt
(
    varname     VARCHAR(30)
   ,case_stmt   VARCHAR(1000)
)
PRIMARY INDEX(varname);


DROP TABLE {db_name}.tbl_account;

CREATE MULTISET TABLE {db_name}.tbl_account
(
    acct_id    INTEGER
   ,start_date DATE
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_outstanding_billing;

CREATE MULTISET TABLE {db_name}.tbl_outstanding_billing
(
    acct_id           INTEGER
   ,billing_month     INTEGER
   ,unpaid_year_month INTEGER
   ,tot_amt_due       FLOAT
   ,tot_amt_paid      FLOAT
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_summary;

CREATE MULTISET TABLE {db_name}.tbl_summary
(
    acct_id    INTEGER
   ,year_month INTEGER
   ,varname    VARCHAR(30)
   ,varvalue   VARCHAR(50)
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_account_prfgrp;

CREATE MULTISET TABLE {db_name}.tbl_account_prfgrp
(
    acct_id    INTEGER
   ,year_month INTEGER
   ,prfgrp     BYTEINT
   ,prf        BYTEINT
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_account_sample;

CREATE TABLE {db_name}.tbl_account_sample
(
    acct_id INTEGER
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_account_sample_fine_bins;

CREATE TABLE {db_name}.tbl_account_sample_fine_bins
(
    acct_id INTEGER
   ,varname VARCHAR(30)
   ,bin_id  BYTEINT
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_sample_woe_iv;

CREATE TABLE {db_name}.tbl_sample_woe_iv
(
    varname VARCHAR(30)
   ,bin_id  BYTEINT
   ,woe     FLOAT
   ,iv      FLOAT
)
PRIMARY INDEX(varname);


DROP TABLE {db_name}.tbl_account_srs;

CREATE TABLE {db_name}.tbl_account_srs
(
    acct_id INTEGER
   ,prfgrp  BYTEINT
   ,target  BYTEINT
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_account_fine_bins;

CREATE TABLE {db_name}.tbl_account_fine_bins
(
    acct_id INTEGER
   ,varname VARCHAR(30)
   ,bin_id  BYTEINT
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_sample_iv_rank;

CREATE MULTISET TABLE {db_name}.tbl_sample_iv_rank
(
    varname VARCHAR(100)
   ,iv      FLOAT
   ,ranknum SMALLINT
)
PRIMARY INDEX(ranknum);


DROP TABLE {db_name}.tbl_account_scoring_fine_bins;

CREATE TABLE {db_name}.tbl_account_scoring_fine_bins
(
    acct_id    INTEGER
   ,year_month INTEGER
   ,varname    VARCHAR(30)
   ,bin_id    VARCHAR(70)
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_account_score;

CREATE MULTISET TABLE {db_name}.tbl_account_score
(
    acct_id    INTEGER
   ,year_month INTEGER
   ,score      FLOAT
)
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_process_dev_month;

CREATE MULTISET TABLE {db_name}.tbl_process_dev_month
(
    perf_start_year_month INTEGER
   ,perf_end_year_month INTEGER
)
PRIMARY INDEX(perf_start_year_month);


DROP TABLE {db_name}.tbl_process_new_month;

CREATE MULTISET TABLE {db_name}.tbl_process_new_month
(
    new_year_month INTEGER
)
PRIMARY INDEX(new_year_month);


DROP TABLE {db_name}.tbl_billing_new;

CREATE MULTISET TABLE {db_name}.tbl_billing_new
AS
(SELECT * FROM {db_name}.tbl_billing)
WITH NO DATA
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_trans_new;

CREATE MULTISET TABLE {db_name}.tbl_trans_new
AS
(SELECT * FROM {db_name}.tbl_trans)
WITH NO DATA
PRIMARY INDEX(acct_id);


DROP TABLE {db_name}.tbl_score_decile_bounds;

CREATE MULTISET TABLE {db_name}.tbl_score_decile_bounds
(
    q           BYTEINT
   ,lower_bound FLOAT
   ,upper_bound FLOAT
)
PRIMARY INDEX(q);


-- also load the data for segments and labels
DROP TABLE {db_name}.tbl_segment;
CREATE TABLE {db_name}.tbl_segment
(
    segment INTEGER
   ,label VARCHAR(200)
)
PRIMARY INDEX ( segment );

 
-- also load the data for segments groups. expects segment group 0 for all and 1 row each for each segment in tbl_segment table
DROP TABLE {db_name}.tbl_segment_groups;
CREATE TABLE {db_name}.tbl_segment_groups
(
    segment_group INTEGER
   ,segment INTEGER
   ,group_label VARCHAR(200)
)
PRIMARY INDEX ( segment_group );


-- should be populated
DROP TABLE {db_name}.tbl_acct_segment;
CREATE TABLE {db_name}.tbl_acct_segment
(
    acct_id INTEGER
   ,segment INTEGER
)
PRIMARY INDEX ( acct_id );


-- populated by shiny
DROP TABLE {db_name}.tbl_seg_scorecard;
CREATE TABLE {db_name}.tbl_seg_scorecard
(
    segment_group INTEGER
   ,group_label VARCHAR(200)
   ,varname VARCHAR(30)
   ,old_bin_id INTEGER
   ,new_label VARCHAR(200)
   ,score FLOAT
)
PRIMARY INDEX ( segment_group );
 
 
--populated by Shiny
DROP TABLE {db_name}.tbl_coarse_classes_seg;
CREATE MULTISET TABLE {db_name}.tbl_coarse_classes_seg
(
    segment_group INTEGER
   ,variable VARCHAR(30)
   ,bin BYTEINT
   ,new_bin VARCHAR(255)
   ,new_label VARCHAR(255)
   ,bin_type VARCHAR(255)
)
PRIMARY INDEX ( segment_group );


--populated by Shiny
DROP TABLE {db_name}.tbl_coarse_classes_woe_seg;
CREATE MULTISET TABLE {db_name}.tbl_coarse_classes_woe_seg
(
    segment_group INTEGER
   ,variable VARCHAR(30)
   ,new_bin VARCHAR(255)
   ,bincount INTEGER
   ,bintargetcount INTEGER
   ,target_pct FLOAT
   ,bingoodcount INTEGER
   ,bingoodpct FLOAT
   ,binbadpct FLOAT
   ,woe FLOAT
)
PRIMARY INDEX ( segment_group );
