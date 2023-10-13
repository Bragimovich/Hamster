CREATE TABLE `il_macon__arrestee_addresses`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `arrestee_id`     BIGINT(20),
  `full_address`          VARCHAR(255),
  `street_address`        VARCHAR(255),
  `unit_number`           VARCHAR(255),
  `city`                  VARCHAR(255),
  `county`                VARCHAR(255),
  `state`                 VARCHAR(255),
  `zip`                   VARCHAR(255),
  `lan`                   VARCHAR(255),
  `lon`                   VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Igor Sas',
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
  COLLATE = utf8mb4_unicode_520_ci;
