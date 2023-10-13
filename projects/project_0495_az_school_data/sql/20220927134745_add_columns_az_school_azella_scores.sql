ALTER TABLE AZ_school_AZELLA_scores
    ADD COLUMN alternative_school VARCHAR(255) DEFAULT NULL AFTER charter;

ALTER TABLE AZ_school_AZELLA_scores
    ADD COLUMN data_type VARCHAR(255) DEFAULT NULL AFTER pct_proficient;

ALTER TABLE AZ_school_AZELLA_scores
    ADD COLUMN report_date DATE NOT NULL AFTER data_type;
