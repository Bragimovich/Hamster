CREATE TABLE us_schools_raw.in_schools_assessment
(
    id	                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    general_id	        BIGINT(20),
    school_year	        VARCHAR(50),
    exam_name	        VARCHAR(255),
    grade	            VARCHAR(255),
    subject	            VARCHAR(255),
    `group`	            VARCHAR(255),
    demographic	        VARCHAR(255),
    number_of_students	VARCHAR(255),
    number_tested	    VARCHAR(255),
    rate_percent	    VARCHAR(255),
    created_by          VARCHAR(255)      DEFAULT 'Danil Kurshanov',
    created_at          DATETIME          DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    data_source_url     VARCHAR(255)      DEFAULT 'https://www.in.gov/doe/it/data-center-and-reports/',
    run_id              BIGINT(20),
    touched_run_id      BIGINT,
    deleted             BOOLEAN           DEFAULT 0,
    md5_hash            VARCHAR(255),
    UNIQUE KEY        md5 (md5_hash),
    INDEX             run_id (run_id),
    INDEX             touched_run_id (touched_run_id),
    INDEX             deleted (deleted)
)   DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Table for task #537. Made by dkurshnov.';