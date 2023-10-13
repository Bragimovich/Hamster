CREATE TABLE `delaware_business_licenses`
(
  `id`                          BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                      BIGINT(20),
  `busines_name`                VARCHAR(255),
  `license_nr`                  VARCHAR(255),
  `business_activity`           VARCHAR(255),
  `valid_from`                  Date,
  `valid_to`                    Date,
  `location`                    VARCHAR(255),
  `md5_hash`                    VARCHAR(255),
  `last_scrape_date`            Date,
  `next_scrape_date`            Date,
  `scrape_frequency`            VARCHAR(255),
  `expected_scrape_frequency`   VARCHAR(255),
  `pl_gather_task_id`           INT,
  `data_source_url`             TEXT,
  `created_by`                  VARCHAR(255)      DEFAULT 'Adeel',
  `created_at`                  DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`              BIGINT,
  `deleted`                     BOOLEAN            DEFAULT 0,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
