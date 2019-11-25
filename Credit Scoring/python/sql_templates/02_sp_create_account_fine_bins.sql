REPLACE PROCEDURE {db_name}.create_account_fine_bins
/*==========================================================================
# Purpose:
#
#     Create the table of fine bins for the accounts and pivot it into the
#     wide format
#
*/
(
)
BEGIN
    DECLARE varname_when_stmts CLOB;
    DECLARE varname_max_stmts CLOB;
    DECLARE sql_stmt LONG VARCHAR;
    DECLARE v_exist INTEGER;

    SET varname_when_stmts = '';
    SET varname_max_stmts = '';

    FOR rec AS cur CURSOR FOR
        SELECT     a.varname, b.case_stmt
        FROM       {db_name}.tbl_sample_iv_rank a
        INNER JOIN {db_name}.tbl_var_case_stmt b
        ON         a.varname = b.varname
        WHERE      a.ranknum <= 200
    DO
        SET varname_when_stmts = varname_when_stmts || CHR(10) || rec.case_stmt;
        SET varname_max_stmts = varname_max_stmts || CHR(10) || '          ,MAX(CASE WHEN varname = ''' || rec.varname || ''' THEN bin_id ELSE NULL END) AS ' || rec.varname;
    END FOR;

    SET varname_when_stmts = SUBSTR(varname_when_stmts, 2, LENGTH(varname_when_stmts));
    SET varname_max_stmts = SUBSTR(varname_max_stmts, 2, LENGTH(varname_max_stmts));

    SET sql_stmt = 'INSERT INTO {db_name}.tbl_account_fine_bins(acct_id, varname, bin_id)'                                                 || CHR(10) ||
                   'SELECT     acct_id'                                                                                                    || CHR(10) ||
                   '          ,a.varname'                                                                                                  || CHR(10) ||
                   '          ,CASE'                                                                                                       || CHR(10) ||
                   varname_when_stmts                                                                                                      || CHR(10) ||
                   '               ELSE NULL'                                                                                              || CHR(10) ||
                   '           END AS bin_id'                                                                                              || CHR(10) ||
                   'FROM       {db_name}.tbl_summary a'                                                                                    || CHR(10) ||
                   'INNER JOIN {db_name}.tbl_sample_iv_rank b'                                                                             || CHR(10) ||
                   'ON         a.varname = b.varname'                                                                                      || CHR(10) ||
                   'WHERE      b.ranknum <= 200'                                                                                           || CHR(10) ||
                   'AND        bin_id IS NOT NULL'                                                                                         || CHR(10) ||
                   'AND        a.year_month = (   -- Last month of the observation period'                                                 || CHR(10) ||
                   '                              SELECT CASE'                                                                             || CHR(10) ||
                   '                                         WHEN perf_start_year_month MOD 100 = 1 THEN perf_start_year_month - 100 + 11' || CHR(10) ||
                   '                                         ELSE perf_start_year_month - 1'                                               || CHR(10) ||
                   '                                     END'                                                                              || CHR(10) ||
                   '                              FROM   {db_name}.tbl_process_dev_month'                                                  || CHR(10) ||
                   '                          )';

    EXECUTE IMMEDIATE sql_stmt;

    -- Pivot
    SELECT 1
    INTO   v_exist
    FROM   dbc.tables
    WHERE  LOWER(databasename) = '{db_name}'
    AND    LOWER(tablename) = 'tbl_account_srs_binned';

    IF v_exist = 1 THEN
        SET sql_stmt = 'DROP TABLE {db_name}.tbl_account_srs_binned';
        EXECUTE IMMEDIATE sql_stmt;
    END IF;

    SET sql_stmt = 'CREATE TABLE {db_name}.tbl_account_srs_binned'    || CHR(10) ||
                   'AS'                                               || CHR(10) ||
                   '('                                                || CHR(10) ||
                   '    SELECT a.acct_id'                             || CHR(10) ||
                   varname_max_stmts                                  || CHR(10) ||
                   '          ,a.target'                              || CHR(10) ||
                   '    FROM       {db_name}.tbl_account_srs a'       || CHR(10) ||
                   '    INNER JOIN {db_name}.tbl_account_fine_bins b' || CHR(10) ||
                   '    ON         a.acct_id = b.acct_id'             || CHR(10) ||
                   '    GROUP BY   a.acct_id, a.target'               || CHR(10) ||
                   ')'                                                || CHR(10) ||
                   'WITH DATA'                                        || CHR(10) ||
                   'PRIMARY INDEX(acct_id)';

    EXECUTE IMMEDIATE sql_stmt;
END;
