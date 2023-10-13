CREATE TABLE us_court_cases.la_1c_ac_case_activities
(
    id                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    court_id            INT,
    case_id             VARCHAR(255),
    activity_date       DATE,
    activity_desc       MEDIUMTEXT,
    activity_type       VARCHAR(255),
    `file`              VARCHAR(255),
    created_by          VARCHAR(255)      DEFAULT 'Danil Kurshanov',
    created_at          DATETIME          DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    data_source_url     VARCHAR(255)      DEFAULT 'https://www.la-fcca.org/index.php/newdecisions.html',
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
    COMMENT = 'Table for task #634. Made by dkurshnov.';