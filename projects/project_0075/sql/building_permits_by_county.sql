CREATE TABLE `building_permits_by_county`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `date` VARCHAR(255),
  `survey_date` INT(7),
  `FIPS_state` VARCHAR(255),
  `FIPS_county` VARCHAR(255),
  `region_code` VARCHAR(255),
  `division_code` VARCHAR(255),
  `county_name` VARCHAR(255),
  `one_unit_bldgs` VARCHAR(255),
  `one_unit_units` VARCHAR(255),
  `one_unit_value` VARCHAR(255),
  `two_units_bldgs` VARCHAR(255),
  `two_units_units` VARCHAR(255),
  `two_units_value` VARCHAR(255),
  `three_four__units_bldgs` VARCHAR(255),
  `three_four__units_units` VARCHAR(255),
  `three_four__units_value` VARCHAR(255),
  `fiveplus__units_bldgs` VARCHAR(255),
  `fiveplus__units_units` VARCHAR(255),
  `fiveplus__units_value` VARCHAR(255),
  `one_units_rep_bldgs` VARCHAR(255),
  `one_units_rep_units` VARCHAR(255),
  `one_units_rep_value` VARCHAR(255),
  `two_units_rep_bldgs` VARCHAR(255),
  `two_units_rep_units` VARCHAR(255),
  `two_units_rep_value` VARCHAR(255),
  `three_four__units_rep_bldgs` VARCHAR(255),
  `three_four__units_rep_units` VARCHAR(255),
  `three_four__units_rep_value` VARCHAR(255),
  `fiveplus__units_rep_bldgs` VARCHAR(255),
  `fiveplus__units_rep_units` VARCHAR(255),
  `fiveplus__units_rep_value` VARCHAR(255),
  `scrape_frequency` VARCHAR(255),
  `data_source_url` TEXT,
  `link` VARCHAR(255),
  `created_by`      VARCHAR(255)      DEFAULT 'Seth Putz',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'This scrape was made by Seth Putz';