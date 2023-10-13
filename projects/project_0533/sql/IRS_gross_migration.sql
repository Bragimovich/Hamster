CREATE TABLE `IRS_gross_migration`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20)         DEFAULT 1,
    `year_1`                INT,
    `year_2`                INT,
    `state`                 VARCHAR(100),
    `state_fips`            VARCHAR(100),
    `amounts`               VARCHAR(100),
    `return_type`           VARCHAR(100),
    `age_1`                 INT,
    `age_2`                 INT,
    `number_of_returns`     BIGINT,
    `number_of_individuals` BIGINT,
    `agi_1`                 BIGINT,
    `agi_2`                 BIGINT,
    `data_source_url`       TEXT,
    `created_by`            VARCHAR(255)      DEFAULT 'Halid Ibragimov',
    `created_at`            DATETIME          DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`        BIGINT(20)            DEFAULT 1,
    `deleted`               BOOLEAN           DEFAULT 0,
    `md5_hash`              VARCHAR(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', CAST(year_1 AS CHAR), CAST(year_2 AS CHAR), state, state_fips, amounts, return_type, CAST(age_1 AS CHAR), CAST(age_2 AS CHAR), CAST(number_of_returns AS CHAR), CAST(number_of_individuals AS CHAR), CAST(agi_1 AS CHAR), CAST(agi_2 AS CHAR) ))),
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE         = utf8mb4_unicode_520_ci
    COMMENT       = 'The Scrape made by Halid Ibragimov';