CREATE UNIQUE INDEX tyq0210_g_id ON TYQ0210 (G_ID);
CREATE UNIQUE INDEX ftir_base_info_f_id ON ftir_base_info (F_ID);
CREATE INDEX ftir_base_info_f_report_country_code ON ftir_base_info (F_REPORT_COUNTRY_CODE);
CREATE INDEX ftir_base_info_f_product_specification ON ftir_base_info (F_PRODUCT_SPECIFICATION);
CREATE INDEX ftir_base_info_f_product_specification ON ftir_base_info (F_PRODUCT_SPECIFICATION);
CREATE INDEX tyq0110_trouble_complaint_code ON tyq0110 (g_trouble_complaint_code);
CREATE UNIQUE INDEX tyq0110_pk ON tyq0110 (G_FPCR_ID);
CREATE UNIQUE INDEX tyq0120_pk ON tyq0120 (G_FPCR_ID, G_CAUSE_ANALYSIS_NO);
CREATE UNIQUE INDEX tyq0220_pk ON tyq0220 (G_ID);
