CREATE TABLE `il_peoria__holding_facilities`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `arrest_id`     BIGINT(20),
  `facility`      VARCHAR(255),
  `facility_type`     VARCHAR(255),
  `facility_subtype`   VARCHAR(255),
  `start_date` DATE,
  `planned_release_date`    DATE,
  `actual_release_date` DATE,
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
