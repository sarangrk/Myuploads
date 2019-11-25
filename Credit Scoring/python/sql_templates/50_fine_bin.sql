-- Get the fine bins of the top variables (~200) for each account in the "full file"
DELETE FROM {db_name}.tbl_account_fine_bins ALL;

CALL {db_name}.create_account_fine_bins();
