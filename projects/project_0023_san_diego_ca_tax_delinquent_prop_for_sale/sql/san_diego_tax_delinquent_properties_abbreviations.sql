CREATE TABLE `san_diego_tax_delinquent_properties_abbreviations`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `abbreviation`        VARCHAR(255),
  `description_meaning` VARCHAR(255),
  `data_source_url` VARCHAR(255)       DEFAULT 'https://www2.sdcounty.ca.gov/treastax/taxsale/table.asp',
  `created_by`      VARCHAR(255)       DEFAULT 'Yunus Ganiyev',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
