DELETE FROM {db_name}.tbl_account_sample_fine_bins ALL;

-- Get the fine bins of all the variables (~5000) for each account in the sample set
INSERT INTO {db_name}.tbl_account_sample_fine_bins(acct_id, varname, bin_id)
SELECT acct_id
      ,varname
      ,CASE
{varname_when_stmts}
           ELSE NULL
       END AS bin_id
FROM   (
           SELECT     a.acct_id, a.varname, varvalue
           FROM       {db_name}.tbl_summary a
           INNER JOIN {db_name}.tbl_account_sample b
           ON         a.acct_id = b.acct_id
           INNER JOIN {db_name}.tbl_variable c
           ON         a.varname = c.varname
           WHERE      a.year_month = (   -- Last month of the observation period
                                         SELECT CASE
                                                    WHEN perf_start_year_month MOD 100 = 1 THEN perf_start_year_month - 100 + 11
                                                    ELSE perf_start_year_month - 1
                                                END
                                         FROM   {db_name}.tbl_process_dev_month
                                     )
       ) t
WHERE  bin_id IS NOT NULL
;


-- Get the performance target of each account in the sample set
CREATE VOLATILE TABLE vt_account_sample_prfgrp
AS
(
    SELECT     a.acct_id
              ,CASE
                   WHEN prfgrp = 3 THEN 1 -- 'Bad'
                   WHEN prfgrp = 4 THEN 1 -- 'Bad'
                   WHEN prfgrp = 7 THEN 0 -- 'Good'
                   ELSE NULL
               END target
    FROM       {db_name}.tbl_account_sample a
    INNER JOIN (
                   -- Use the last year_month of the performance window
                   SELECT     x.acct_id, x.prfgrp
                   FROM       {db_name}.tbl_account_prfgrp x
                   INNER JOIN {db_name}.tbl_process_dev_month y
                   ON         x.year_month = y.perf_end_year_month
               ) b
    ON         a.acct_id = b.acct_id
    WHERE      target IS NOT NULL
)
WITH DATA
PRIMARY INDEX(acct_id)
ON COMMIT PRESERVE ROWS;


CREATE VOLATILE TABLE vt_fine_bin_count_pct
AS
(
    WITH fine_bin_count AS
    (
        SELECT    a.varname
                 ,a.bin_id
                 ,a.target
                 ,COALESCE(b.target_count, 1) AS target_count -- count adjusted to avoid /0 or ln(0)
        FROM      (
                     -- cross join bins and targets (0 and 1)
                     SELECT     a.varname, a.bin_id, b.target
                     FROM       {db_name}.tbl_var_fine_bins a
                     INNER JOIN (
                                    SELECT target FROM (SELECT 0 AS target) x
                                    UNION ALL 
                                    SELECT target FROM (SELECT 1 AS target) y
                                ) b
                     ON         1 = 1
                  ) a
        LEFT JOIN (          
                      SELECT     a.varname, a.bin_id, b.target, COUNT(*) + 1 AS target_count -- count adjusted to avoid /0 or ln(0)
                      FROM       {db_name}.tbl_account_sample_fine_bins a
                      INNER JOIN vt_account_sample_prfgrp b
                      ON         a.acct_id = b.acct_id
                      GROUP BY   a.varname, a.bin_id, b.target          
                  ) b
        ON     a.varname = b.varname
        AND    a.bin_id = b.bin_id
        AND    a.target = b.target
    )
    SELECT     a.varname, a.bin_id, a.target, CAST(target_count AS FLOAT)/target_total pct
    FROM       fine_bin_count a
    INNER JOIN (
                   SELECT varname, target, SUM(target_count) AS target_total
                   FROM   fine_bin_count
                   GROUP BY varname, target
               ) AS b
    ON         a.varname = b.varname
    AND        a.target = b.target
)
WITH DATA
PRIMARY INDEX(varname)
ON COMMIT PRESERVE ROWS;


DELETE FROM {db_name}.tbl_sample_woe_iv ALL;

INSERT INTO {db_name}.tbl_sample_woe_iv(varname, bin_id, woe, iv)
SELECT     good.varname
          ,good.bin_id
          ,LN(good.pct / bad.pct)
          ,(good.pct - bad.pct) * LN(good.pct / bad.pct)
FROM       vt_fine_bin_count_pct good
INNER JOIN vt_fine_bin_count_pct bad
ON         good.varname = bad.varname
AND        good.bin_id = bad.bin_id
AND        good.target = 0
AND        bad.target = 1;


DROP TABLE vt_account_sample_prfgrp;

DROP TABLE vt_fine_bin_count_pct;


DELETE FROM {db_name}.tbl_sample_iv_rank ALL;

INSERT INTO {db_name}.tbl_sample_iv_rank
SELECT varname, total_iv, rank() OVER(ORDER BY total_iv DESC)
FROM   (
           SELECT varname, SUM(iv) AS total_iv
           FROM   {db_name}.tbl_sample_woe_iv
           GROUP BY varname
       ) t;


