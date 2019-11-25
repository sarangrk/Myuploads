-- Scoring
DELETE FROM {db_name}.tbl_account_scoring_fine_bins ALL;

INSERT INTO {db_name}.tbl_account_scoring_fine_bins
SELECT acct_id
      ,year_month
      ,varname
      ,CASE
{varname_when_stmts}
       END AS bin_id
FROM   {db_name}.tbl_summary
WHERE  varname IN (SELECT DISTINCT varname FROM {db_name}.tbl_seg_scorecard)
AND    year_month IN (   -- Last month of the observation period (development)
                         SELECT CASE
                                    WHEN perf_start_year_month MOD 100 = 1 THEN perf_start_year_month - 100 + 11
                                    ELSE perf_start_year_month - 1
                                END
                         FROM   {db_name}.tbl_process_dev_month
                         UNION ALL
                         -- Last month of the performance period
                         SELECT perf_end_year_month
                         FROM   {db_name}.tbl_process_dev_month
                     );


DELETE FROM {db_name}.tbl_account_score ALL;

INSERT INTO {db_name}.tbl_account_score(acct_id, year_month, score)
SELECT     a.acct_id, a.year_month, SUM(b.score)
FROM       {db_name}.tbl_account_scoring_fine_bins a
INNER JOIN {db_name}.tbl_seg_scorecard b
ON         a.varname = b.varname
AND        a.bin_id = b.old_bin_id
INNER JOIN {db_name}.tbl_segment_groups c
ON         b.segment_group = c.segment_group
INNER JOIN {db_name}.tbl_acct_segment d
ON         a.acct_id = d.acct_id
AND        c.segment = d.segment
GROUP BY   a.acct_id, a.year_month;


-- Get the deciles of the scores to be used for reporting
DELETE FROM {db_name}.tbl_score_decile_bounds ALL;

INSERT INTO {db_name}.tbl_score_decile_bounds
SELECT q
      ,CASE
           WHEN q = 0 THEN -1e+12
           ELSE MIN(max_score) OVER(ORDER BY q ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
       END AS lower_bound
      ,CASE
           WHEN q = 9 THEN 1e+12
           ELSE max_score
       END AS upper_bound
FROM   (
           SELECT q
                 ,MIN(score) AS min_score
                 ,MAX(score) AS max_score
           FROM   (
                      SELECT acct_id
                            ,score
                            ,(RANK() OVER (ORDER BY ROUND(score)) - 1) * 10 / COUNT(*) OVER() AS q
                      FROM   {db_name}.tbl_account_score
                      WHERE  year_month = (
                                              SELECT CASE
                                                         WHEN perf_start_year_month MOD 100 = 1 THEN perf_start_year_month - 100 + 11
                                                         ELSE perf_start_year_month - 1
                                                     END
                                              FROM   {db_name}.tbl_process_dev_month
                                          )
                  ) t
           GROUP BY q
) t;

