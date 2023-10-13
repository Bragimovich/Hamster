ALTER TABLE AZ_school_AzMERIT_and_MSAA_scores
    ADD COLUMN alternative_school VARCHAR(255) DEFAULT NULL AFTER charter;

ALTER TABLE AZ_school_AzMERIT_and_MSAA_scores
    ADD COLUMN pct_tested VARCHAR(255) DEFAULT NULL AFTER pct_performance_level_4;

ALTER TABLE AZ_school_AzMERIT_and_MSAA_scores
    ADD COLUMN report_date DATE NOT NULL AFTER pct_tested;


