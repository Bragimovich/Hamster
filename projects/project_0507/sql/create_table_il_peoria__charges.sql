CREATE TABLE `il_peoria__charges`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `arrest_id`     BIGINT(20),
  `number`      VARCHAR(255),
  `disposition` TEXT,
  `disposition_date`    DATE,
  `description` TEXT,
  `offense_date`    DATE,
  `offense_time`    TIME,
  `crime_class`     VARCHAR(255),
  `attempt_or_commit`   VARCHAR(255),
  `docket_number`   VARCHAR(255),
  `bond_number`     VARCHAR(255),
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
