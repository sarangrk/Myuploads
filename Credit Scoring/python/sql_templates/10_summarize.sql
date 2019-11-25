/* Insert outstanding billing */
DELETE FROM {db_name}.tbl_outstanding_billing ALL;

INSERT INTO {db_name}.tbl_outstanding_billing(acct_id, billing_month, unpaid_year_month, tot_amt_due, tot_amt_paid)
SELECT x.acct_id
      ,TO_NUMBER(TO_CHAR(x.dt_due, 'YYYYMM'))
      ,y.year_month
      ,y.tot_amt_due
      ,x.tot_amt_paid
FROM   (
           SELECT acct_id
                 ,dt_due
                 ,dt_paid
                 ,amt_paid
                 ,SUM(amt_paid) OVER (PARTITION BY acct_id ORDER BY dt_due, dt_paid ROWS UNBOUNDED PRECEDING) AS tot_amt_paid
           FROM   {db_name}.tbl_trans
           QUALIFY ROW_NUMBER() OVER (PARTITION BY acct_id, dt_due ORDER BY dt_paid DESC) = 1
       ) x
LEFT JOIN
       (
           SELECT b.*, SUM(amt_due) OVER(PARTITION BY acct_id ORDER BY year_month ROWS UNBOUNDED PRECEDING) AS tot_amt_due
           FROM   {db_name}.tbl_billing b
       ) y
ON     x.acct_id = y.acct_id
AND    x.tot_amt_paid < y.tot_amt_due
AND    TO_NUMBER(TO_CHAR(x.dt_due, 'YYYYMM')) >= y.year_month;


/* Clear summary table */
DELETE FROM {db_name}.tbl_summary ALL;

/* Insert total_amt_paid */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT   acct_id, TO_NUMBER(TO_CHAR(dt_due, 'YYYYMM')) etl_date, 'amt_paid', TO_CHAR(SUM(amt_paid))
FROM     {db_name}.tbl_trans
GROUP BY acct_id, etl_date;


/* Insert total_amt_due */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT   acct_id, year_month, 'amt_due', TO_CHAR(SUM(amt_due))
FROM     {db_name}.tbl_billing
GROUP BY acct_id, year_month;


/* Insert mob */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT     a.acct_id
          ,a.year_month
          ,'mob'
          ,TO_CHAR(MAX(((a.year_month / 100) - TO_NUMBER(TO_CHAR(b.start_date, 'YYYY'))) * 12 + ((a.year_month MOD 100) - TO_NUMBER(TO_CHAR(b.start_date, 'MM')))))
FROM       {db_name}.tbl_trans a
INNER JOIN {db_name}.tbl_account b
ON         a.acct_id = b.acct_id
GROUP BY   a.acct_id, a.year_month;


/* Insert dq_eom */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT acct_id
      ,billing_month
      ,'dq_eom'
      ,CASE
           WHEN MIN(unpaid_year_month) IS NULL THEN '0'
           ELSE TO_CHAR((TO_DATE(TO_CHAR(billing_month), 'YYYYMM') + 27) - (TO_DATE(TO_CHAR(MIN(unpaid_year_month)), 'YYYYMM') + 19))
       END dq_eom
FROM   {db_name}.tbl_outstanding_billing
GROUP BY acct_id, billing_month;


/* Insert dq_max */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT acct_id
      ,billing_month
      ,'dq_max'
      ,TO_CHAR(MIN(days))
FROM   (
           SELECT acct_id
                 ,billing_month
                 ,CASE
                      WHEN dq_max_computation = 'dt_paid - dt_due' THEN
                          CASE
                              WHEN dt_paid IS NULL THEN 0  -- this is the case when there was an advance payment from previous month
                              WHEN dt_paid < dt_due THEN 0
                              ELSE dt_paid - dt_due
                          END
                      WHEN dq_max_computation = 'dt_paid - minimum unpaid due date' THEN dt_paid - min_upaid_dt_due
                      WHEN dq_max_computation = 'current eom - dt_due' THEN curr_eom - dt_due
                      WHEN dq_max_computation = 'current eom - minimum unpaid due date' THEN curr_eom - min_upaid_dt_due
                  END days
           FROM   (
                      SELECT a.acct_id
                            ,a.billing_month
                            ,a.dq_max_computation
                            ,a.prev_min_unpaid
                            ,b.dt_due
                            ,b.dt_paid
                            ,TO_DATE(TO_CHAR(a.prev_min_unpaid), 'YYYYMM') + 19 AS min_upaid_dt_due
                            ,b.dt_due + 8 AS curr_eom
                            ,CASE
                                 WHEN dq_max_computation = 'dt_paid - minimum unpaid due date' AND b.tot_amt_paid < COALESCE(prev_min_unpaid_amt_due, 0) THEN NULL -- not yet paid
                                 ELSE 'Y'
                             END include
                      FROM   (
                                 SELECT curr.acct_id
                                       ,curr.billing_month
                                       ,MIN(prev.unpaid_year_month) prev_min_unpaid
                                       ,MIN(curr.unpaid_year_month) curr_min_unpaid
                                       ,MIN(prev.tot_amt_due) prev_min_unpaid_amt_due
                                       ,CASE
                                            WHEN MIN(curr.unpaid_year_month) IS NULL AND MIN(prev.unpaid_year_month) IS NULL     -- no outstanding
                                                 THEN 'dt_paid - dt_due'
                                            WHEN MIN(curr.unpaid_year_month) IS NULL AND MIN(prev.unpaid_year_month) IS NOT NULL -- cured all by end of current month
                                                 THEN 'dt_paid - minimum unpaid due date'
                                            WHEN MIN(curr.unpaid_year_month) IS NOT NULL AND MIN(prev.unpaid_year_month) IS NULL -- just started to be delinquent
                                                 THEN 'current eom - dt_due'
                                            WHEN MIN(curr.unpaid_year_month) = MIN(prev.unpaid_year_month)                       -- has outstanding from previous and didn't cure any
                                                 THEN 'current eom - minimum unpaid due date'
                                            ELSE                                                                                 -- has outstanding from previous and cured some
                                                 'dt_paid - minimum unpaid due date'
                                        END AS dq_max_computation
                                 FROM   {db_name}.tbl_outstanding_billing curr
                                 LEFT JOIN
                                        {db_name}.tbl_outstanding_billing prev
                                 ON     prev.acct_id = curr.acct_id
                                 AND    curr.billing_month = CASE
                                                                 WHEN prev.billing_month MOD 100 = 12 THEN prev.billing_month + 100 - 11
                                                                 ELSE prev.billing_month + 1
                                                             END
                                 GROUP BY curr.acct_id, curr.billing_month
                             ) a
                      LEFT JOIN
                             (
                                 SELECT acct_id
                                       ,dt_due
                                       ,dt_paid
                                       ,amt_paid
                                       ,SUM(amt_paid) OVER (PARTITION BY acct_id ORDER BY dt_due, dt_paid ROWS UNBOUNDED PRECEDING) AS tot_amt_paid
                                 FROM   {db_name}.tbl_trans
                             ) b
                      ON     a.acct_id = b.acct_id
                      AND    a.billing_month = TO_NUMBER(TO_CHAR(b.dt_due, 'YYYYMM'))
                  ) t
           WHERE  include = 'Y'
       ) t
GROUP BY acct_id, billing_month;


/* Insert dq_status */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT acct_id
      ,year_month
      ,'dq_status'
      ,CASE
           WHEN varvalue = '0' THEN '0'
           ELSE '1'
       END
FROM   {db_name}.tbl_summary
WHERE  varname = 'dq_eom';


/* Insert n_dq counters */
{n_dq_x_stmts}


/* Insert dq_eom change */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT curr.acct_id, curr.year_month, 'dq_eom_change',
       TO_CHAR(CAST(curr.varvalue AS INTEGER) - COALESCE(CAST(prev.varvalue AS INTEGER), 0)) AS change
FROM   (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom'
       ) curr
LEFT JOIN
       (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom'
       ) prev
ON     curr.acct_id = prev.acct_id
AND    prev.year_month = CASE
                             WHEN curr.year_month MOD 100 = 1 THEN curr.year_month - 100 + 11
                             ELSE curr.year_month - 1
                         END;


/* Insert dq_eom increasing counter */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT curr.acct_id, curr.year_month, 'dq_eom_inc',
       TO_CHAR(ROW_NUMBER() OVER (PARTITION BY curr.acct_id ORDER BY curr.acct_id, curr.year_month RESET WHEN CAST(curr.varvalue AS INTEGER) <= COALESCE(CAST(prev.varvalue AS INTEGER), 0)) -1)
FROM   (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom'
       ) curr
LEFT JOIN
       (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom'
       ) prev
ON     curr.acct_id = prev.acct_id
AND    prev.year_month = CASE
                             WHEN curr.year_month MOD 100 = 1 THEN curr.year_month - 100 + 11
                             ELSE curr.year_month - 1
                         END;


/* Insert dq_eom decreasing counter */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT curr.acct_id, curr.year_month, 'dq_eom_dec',
       TO_CHAR(ROW_NUMBER() OVER (PARTITION BY curr.acct_id ORDER BY curr.acct_id, curr.year_month RESET WHEN CAST(curr.varvalue AS INTEGER) >= COALESCE(CAST(prev.varvalue AS INTEGER), 0)) -1)
FROM   (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom'
       ) curr
LEFT JOIN
       (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom'
       ) prev
ON     curr.acct_id = prev.acct_id
AND    prev.year_month = CASE
                             WHEN curr.year_month MOD 100 = 1 THEN curr.year_month - 100 + 11
                             ELSE curr.year_month - 1
                         END;


/* Insert dq_eom change 2 */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT curr.acct_id, curr.year_month, 'dq_eom_change2',
       TO_CHAR(CAST(curr.varvalue AS INTEGER) - COALESCE(CAST(prev.varvalue AS INTEGER), 0)) AS change
FROM   (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom_change'
       ) curr
LEFT JOIN
       (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom_change'
       ) prev
ON     curr.acct_id = prev.acct_id
AND    prev.year_month = CASE
                             WHEN curr.year_month MOD 100 = 1 THEN curr.year_month - 100 + 11
                             ELSE curr.year_month - 1
                         END;


/* Insert dq_eom increasing counter 2 */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT curr.acct_id, curr.year_month, 'dq_eom_inc2',
       TO_CHAR(ROW_NUMBER() OVER (PARTITION BY curr.acct_id ORDER BY curr.acct_id, curr.year_month RESET WHEN CAST(curr.varvalue AS INTEGER) <= COALESCE(CAST(prev.varvalue AS INTEGER), 0)) -1)
FROM   (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom_change'
       ) curr
LEFT JOIN
       (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom_change'
       ) prev
ON     curr.acct_id = prev.acct_id
AND    prev.year_month = CASE
                             WHEN curr.year_month MOD 100 = 1 THEN curr.year_month - 100 + 11
                             ELSE curr.year_month - 1
                         END;


/* Insert dq_eom decreasing counter 2 */
INSERT INTO {db_name}.tbl_summary(acct_id, year_month, varname, varvalue)
SELECT curr.acct_id, curr.year_month, 'dq_eom_dec2',
       TO_CHAR(ROW_NUMBER() OVER (PARTITION BY curr.acct_id ORDER BY curr.acct_id, curr.year_month RESET WHEN CAST(curr.varvalue AS INTEGER) >= COALESCE(CAST(prev.varvalue AS INTEGER), 0)) -1)
FROM   (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom_change'
       ) curr
LEFT JOIN
       (
           SELECT acct_id, year_month, varvalue
           FROM   {db_name}.tbl_summary curr
           WHERE  varname = 'dq_eom_change'
       ) prev
ON     curr.acct_id = prev.acct_id
AND    prev.year_month = CASE
                             WHEN curr.year_month MOD 100 = 1 THEN curr.year_month - 100 + 11
                             ELSE curr.year_month - 1
                         END;



