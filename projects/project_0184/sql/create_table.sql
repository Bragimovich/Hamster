CREATE TABLE press_releases.exim
(
    id              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(255),
    teaser          TEXT,
    article         LONGTEXT,
    with_table      TINYINT(1),
    dirty_news      TINYINT(1)        DEFAULT 0,
    date            DATE,
    link            VARCHAR(255),
    creator         VARCHAR(255)      DEFAULT 'Export-Import Bank',
    contact_info    TEXT,
    type            VARCHAR(255)      DEFAULT 'press-release',
    country         VARCHAR(255)      DEFAULT 'US',
    created_by      VARCHAR(255)      DEFAULT 'Danil Kurshanov',
    created_at      DATETIME          DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    data_source_url VARCHAR(255)      DEFAULT 'https://www.exim.gov/news',
    run_id          BIGINT(20),
    touched_run_id  BIGINT,
    deleted         BOOLEAN           DEFAULT 0,
    md5_hash        VARCHAR(255),
    UNIQUE KEY        md5 (md5_hash),
    INDEX             run_id (run_id),
    INDEX             touched_run_id (touched_run_id),
    INDEX             deleted (deleted)
)   DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Table for task #184. Made by dkurshnov.';
