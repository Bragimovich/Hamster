CREATE TABLE `minnesota_business_license_trademark_base_data`
(
  `id`                   BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`               BIGINT(20),
  `company_id`           TEXT,
  `business_name`        TEXT,
  `business_type`        TEXT,
  `mn_statute`           TEXT,
  `file_number`          TEXT,
  `home_jurisdiction`    TEXT,
  `filing_date`          DATE      NOT NULL DEFAULT '0000-00-00',
  `filing_date_raw`      TEXT,
  `status`               TEXT,
  `renewal_due_date`     DATE      NOT NULL DEFAULT '0000-00-00',
  `renewal_due_date_raw` TEXT,
  `number_of_shares`     TEXT,
  `mark_type`            TEXT,
  `comments`             TEXT,
  `data_source_url`      TEXT,
  `created_by`           VARCHAR(255)       DEFAULT 'Art Jarocki',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`       BIGINT,
  `deleted`              BOOLEAN            DEFAULT 0,
  `md5_hash`             VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
