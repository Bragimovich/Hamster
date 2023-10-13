CREATE TABLE usa_raw.cei_data_rating
(
    id                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    cei_data_id             INT,
    name                    VARCHAR(255),
    rating                  INT,
    created_by              VARCHAR(255)      DEFAULT 'Danil Kurshanov',
    created_at              DATETIME          DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    data_source_url         VARCHAR(255)      ,
    run_id                  BIGINT(20),
    touched_run_id          BIGINT,
    deleted                 BOOLEAN           DEFAULT 0,
    md5_hash                VARCHAR(255),
    UNIQUE KEY        md5 (md5_hash),
    INDEX             run_id (run_id),
    INDEX             touched_run_id (touched_run_id),
    INDEX             deleted (deleted)
)   DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Table for task #754. Made by dkurshnov.';