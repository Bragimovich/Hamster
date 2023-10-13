ALTER TABLE az_school_enroll_scores
    ADD COLUMN missing_ethnicity VARCHAR(255) DEFAULT NULL AFTER native_hawaiian_pacific_islander;