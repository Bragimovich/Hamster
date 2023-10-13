CREATE TABLE `zip_code_business_patterns`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `zip_code`        VARCHAR(255),
  `county`          VARCHAR(255),
  `state`          VARCHAR(255),
  `naics_industry_code`   VARCHAR(255),
  `num_establishments_total` INT(255),
  `num_establishments_1_to_4_employees` INT(255),
  `num_establishments_5_to_9_employees` INT(255),
  `num_establishments_10_to_19_employees` INT(255),
  `num_establishments_20_to_49_employees` INT(255),
  `num_establishments_50_to_99_employees` INT(255),
  `num_establishments_100_to_249_employees` INT(255),
  `num_establishments_250_to_499_employees` INT(255),
  `num_establishments_500_to_999_employees` INT(255),
  `num_establishments_1000_or_more_employees` INT(255),
  `year` INT(255),
  `data_source_url` VARCHAR(255) DEFAULT "https://www.census.gov/programs-surveys/cbp/data/datasets.html",
  `scrape_dev_name`      VARCHAR(255)      DEFAULT 'Adeel',
  `scrape_frequency`        VARCHAR(255)  DEFAULT 'yearly',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`          VARCHAR(255) GENERATED ALWAYS AS (md5(concat_ws('',CAST(zip_code AS CHAR), county, state, naics_industry_code, CAST(year AS CHAR), CAST(num_establishments_total AS CHAR), CAST(num_establishments_1_to_4_employees AS CHAR), CAST(num_establishments_5_to_9_employees AS CHAR), CAST(num_establishments_10_to_19_employees AS CHAR), CAST(num_establishments_20_to_49_employees AS CHAR),CAST(num_establishments_50_to_99_employees AS CHAR),CAST(num_establishments_100_to_249_employees AS CHAR), CAST(num_establishments_250_to_499_employees AS CHAR), CAST(num_establishments_500_to_999_employees AS CHAR), CAST(num_establishments_1000_or_more_employees AS CHAR)))) STORED,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Adeel';
