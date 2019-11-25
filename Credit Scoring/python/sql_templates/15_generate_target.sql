/* Create temporary table */
CREATE GLOBAL TEMPORARY TABLE {db_name}.tmp_summary_max_dq
(
    acct_id      INTEGER
   ,year_month   INTEGER
   ,f_default    BYTEINT
   ,max_n_dq_120_plus BYTEINT
   ,max_n_dq_120 BYTEINT
   ,max_n_dq_90  BYTEINT
   ,max_n_dq_60  BYTEINT
   ,max_n_dq_30  BYTEINT
   ,max_n_dq_20  BYTEINT
   ,max_n_dq_10  BYTEINT
   ,max_n_dq_3   BYTEINT
   ,max_n_dq_1   BYTEINT
   ,max_n_dq_0   BYTEINT
   ,max_mob      BYTEINT
   ,max_amt_paid DECIMAL(32,2)
)
PRIMARY INDEX(acct_id)
ON COMMIT PRESERVE ROWS;


/* Using the ever-definition, no need for year-month filter */
INSERT INTO {db_name}.tmp_summary_max_dq
SELECT acct_id
      ,year_month
      ,MAX(f_default) AS f_default
	  ,MAX(n_dq_120_plus) AS n_dq_120_plus
      ,MAX(n_dq_120) AS n_dq_120
      ,MAX(n_dq_90) AS n_dq_90
      ,MAX(n_dq_60) AS n_dq_60
      ,MAX(n_dq_30) AS n_dq_30
      ,MAX(n_dq_20) AS n_dq_20
      ,MAX(n_dq_10) AS n_dq_10
      ,MAX(n_dq_3) AS n_dq_3
      ,MAX(n_dq_1) AS n_dq_1
	  ,MAX(n_dq_0) AS n_dq_0
      ,MAX(mob) AS mob
	  ,MAX(amt_paid) AS amt_paid
FROM   (
           SELECT acct_id
                 ,year_month
                 ,CASE varname
                      WHEN 'f_default' THEN TO_NUMBER(varvalue)
                  END AS f_default
				  ,CASE varname
                      WHEN 'n_dq_120+' THEN TO_NUMBER(varvalue)
                  END AS n_dq_120_plus
                 ,CASE varname
                      WHEN 'n_dq_120' THEN TO_NUMBER(varvalue)
                  END AS n_dq_120
                 ,CASE varname
                      WHEN 'n_dq_90' THEN TO_NUMBER(varvalue)
                  END AS n_dq_90
                 ,CASE varname
                      WHEN 'n_dq_60' THEN TO_NUMBER(varvalue)
                  END AS n_dq_60
                 ,CASE varname
                      WHEN 'n_dq_30' THEN TO_NUMBER(varvalue)
                  END AS n_dq_30
                 ,CASE varname
                      WHEN 'n_dq_20' THEN TO_NUMBER(varvalue)
                  END AS n_dq_20
                 ,CASE varname
                      WHEN 'n_dq_10' THEN TO_NUMBER(varvalue)
                  END AS n_dq_10
                 ,CASE varname
                      WHEN 'n_dq_3' THEN TO_NUMBER(varvalue)
                  END AS n_dq_3
                 ,CASE varname
                      WHEN 'n_dq_1' THEN TO_NUMBER(varvalue)
                  END AS n_dq_1
				  ,CASE varname
                      WHEN 'n_dq_0' THEN TO_NUMBER(varvalue)
                  END AS n_dq_0
                 ,CASE varname
                      WHEN 'mob' THEN TO_NUMBER(varvalue)
                  END AS mob
				  ,CASE varname
                      WHEN 'amt_paid' THEN CAST(varvalue AS DECIMAL(32,2))
                  END AS amt_paid
           FROM   {db_name}.tbl_summary
           WHERE  varname IN ('f_default', 'n_dq_120+','n_dq_120', 'n_dq_90', 'n_dq_60', 'n_dq_30', 'n_dq_20', 'n_dq_10', 'n_dq_3', 'n_dq_1','n_dq_0', 'mob','amt_paid')
       ) T
GROUP BY acct_id, year_month;

/* Clear target table */
DELETE {db_name}.tbl_account_prfgrp ALL;

/* Exclusions */
INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 0, 3
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.f_default > 0;

/* Rejects */

/* Bads */
INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 3, 33
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_120_plus > 0;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 3, 34
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_120 > 0;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 3, 35
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_90 > 0;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 3, 36
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_60 > 0;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 4, 40
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_30 > 2;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 4, 41
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_30 = 2;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 4, 42
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_30 = 1;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 4, 43
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_20 > 2;

/*Indeterminates*/

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 5, 50
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_20 = 2;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 5, 51
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_20 = 1;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 5, 52
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_10 > 4;


/* Insufficients */
INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 6, 60
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_mob <= 6;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 6, 61
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_amt_paid <= 10000;

/* Goods */
INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 7, 70
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_10 = 4;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 7, 71
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_10 = 3;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 7, 72
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_10 = 2;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 7, 73
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_10 = 1;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 7, 74
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_3 > 0;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 7, 75
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_1 > 0;

INSERT INTO {db_name}.tbl_account_prfgrp(acct_id, year_month, prfgrp, prf)
SELECT    t1.acct_id, t1.year_month, 7, 76
FROM      tmp_summary_max_dq t1
LEFT JOIN {db_name}.tbl_account_prfgrp t2
ON        t1.acct_id = t2.acct_id
AND       t1.year_month = t2.year_month
WHERE     t2.acct_id IS NULL
AND       t1.max_n_dq_0 > 0;


/* Drop temporary table */
DROP TABLE {db_name}.tmp_summary_max_dq;

