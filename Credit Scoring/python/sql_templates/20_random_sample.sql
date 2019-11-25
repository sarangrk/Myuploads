DELETE FROM {db_name}.tbl_account_sample ALL;

INSERT INTO {db_name}.tbl_account_sample
SELECT acct_id
FROM   (
           SELECT     a.acct_id
           FROM       (
                          SELECT acct_id
                          FROM   {db_name}.tbl_account
                          WHERE  start_date < (   -- Make sure the account was opened at least 6 months before the start of performance window
                                                  SELECT CASE
                                                             WHEN perf_start_year_month MOD 100 > 6 THEN TO_DATE(TO_CHAR(perf_start_year_month - 6), 'YYYYMM')
                                                             ELSE TO_DATE(TO_CHAR(perf_start_year_month - 100 + 6), 'YYYYMM')
                                                         END
                                                  FROM   {db_name}.tbl_process_dev_month
                                              )
                      ) a
           INNER JOIN (    -- Only those accounts that reach the end of the performance window
                          SELECT acct_id
                          FROM   {db_name}.tbl_account_prfgrp
                          WHERE  year_month = (SELECT perf_end_year_month FROM {db_name}.tbl_process_dev_month)
                      ) b
           ON         a.acct_id = b.acct_id
       ) t
SAMPLE 10000;
