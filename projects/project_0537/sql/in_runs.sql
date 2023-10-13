CREATE TABLE us_schools_raw.in_runs
(
    id	            BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    status          VARCHAR(255)      DEFAULT 'processing',
    created_by      VARCHAR(255)      DEFAULT 'Danil Kurshanov',
    created_at      DATETIME          DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

)   DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Table for task #537. Made by dkurshnov.';