python src/scripts/make_lda_model_plda.py --parsed data/interim/FTIR_base_info_JP_4wheels_col_F_ID-F_FAULT_PROPOSAL_LL_0.4_s0-rep_hyph_parsed.csv  --num_topics 30 --ignored_topics 12 16 22 --grouping_table_path data/interim/F_ID-F_SELLING_MODEL_SIGN.csv &
python src/scripts/make_lda_model_plda.py --parsed data/interim/FTIR_base_info_JP_4wheels_col_F_ID-F_FAULT_PROPOSAL_LL_0.4_s0-rep_hyph_parsed.csv  --num_topics 30 --grouping_table_path data/interim/F_ID-F_SELLING_MODEL_SIGN.csv &
python src/scripts/make_lda_model_plda.py --parsed data/interim/FTIR_base_info_JP_4wheels_col_F_ID-F_FAULT_PROPOSAL_LL_0.4_s0-rep_hyph_parsed.csv  --num_topics 100 --grouping_table_path data/interim/F_ID-F_SELLING_MODEL_SIGN.csv &
