CREATE TABLE gasbuddy_v2_gas_prices
(
    id                       BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    station_id               BIGINT    NOT NULL,
    zip_searched             CHAR(10)  NOT NULL,
    is_pay_available         BOOLEAN,
    fuel_type                VARCHAR(255),
    pwgb_discount            DECIMAL(6, 2),
    credit_price             DECIMAL(6, 2),
    price_credit_posted_time DATETIME,
    cash_price               DECIMAL(6, 2),
    price_cash_posted_time   DATETIME,
    data_source_url          VARCHAR(255),
    run_id                   BIGINT NULL,
    touched_run_id           BIGINT NULL,
    deleted                  TINYINT(1) DEFAULT 0 NULL,
    md5_hash                 VARCHAR(255) NULL,
    created_by               VARCHAR(255)       DEFAULT 'Alim L.',
    created_at               DATETIME           DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX                    `run_id` (`run_id`),
    INDEX                    `touched_run_id` (`touched_run_id`),
    INDEX                    `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;