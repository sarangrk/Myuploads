DELETE FROM {db_name}.tbl_account_srs ALL;

INSERT INTO {db_name}.tbl_account_srs(acct_id, prfgrp, target)
SELECT *
FROM   (
           SELECT     a.acct_id
                     ,prfgrp
                     ,CASE
                          WHEN prfgrp = 7 THEN 0
                          WHEN prfgrp IN (3, 4) THEN 1
                      END AS target
           FROM       {db_name}.tbl_account_prfgrp a
           INNER JOIN -- Use the last year_month of the performance window
                      {db_name}.tbl_process_dev_month b
           ON         a.year_month = b.perf_end_year_month
           INNER JOIN {db_name}.tbl_account c
           ON         a.acct_id = c.acct_id
           WHERE      c.start_date < (   -- 6 months before the start of performance window
                                         SELECT CASE
                                                    WHEN perf_start_year_month MOD 100 > 6 THEN TO_DATE(TO_CHAR(perf_start_year_month - 6), 'YYYYMM')
                                                    ELSE TO_DATE(TO_CHAR(perf_start_year_month - 100 + 6), 'YYYYMM')
                                                END
                                         FROM   {db_name}.tbl_process_dev_month
                                     )
       ) t
       SAMPLE
           WHEN prfgrp = 7 THEN 2000
           WHEN prfgrp IN (3, 4) THEN 2000
       END
;

