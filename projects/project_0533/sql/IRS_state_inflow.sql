CREATE TABLE `IRS_state_inflow`
(
  `id`                           BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                       BIGINT(20)        DEFAULT 1,
  `year_1`                       INT,
  `year_2`                       INT,
  `origin_state_fips`            INT,
  `destination_state_fips`       INT,
  `destination_state_name`       VARCHAR(100),
  `number_of_returns`            INT,
  `number_of_exemptions`         INT,
  `adjusted_gross_income`        INT,
  `data_source_url`              TEXT,
  `created_by`                   VARCHAR(255)      DEFAULT 'Halid Ibragimov',
  `created_at`                   DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`               BIGINT(20)            DEFAULT 1,
  `deleted`                      BOOLEAN           DEFAULT 0,
  `md5_hash`                     VARCHAR(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', CAST(year_1 AS CHAR), CAST(year_2 AS CHAR), CAST(origin_state_fips AS CHAR), CAST(destination_state_fips AS CHAR), destination_state_name, CAST(number_of_returns AS CHAR), CAST(number_of_exemptions AS CHAR), CAST(adjusted_gross_income AS CHAR) ))),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE         = utf8mb4_unicode_520_ci
    COMMENT       = 'The Scrape made by Halid Ibragimov';
