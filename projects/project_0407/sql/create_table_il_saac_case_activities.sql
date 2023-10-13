CREATE TABLE `il_saac_case_activities`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                  BIGINT(20),
  `court_id`                VARCHAR(255),
  `case_id`                 VARCHAR(255),
  `activity_date`           DATE,
  `activity_desc`           TEXT,
  `activity_type`           VARCHAR(255),
  `file`                    TEXT,
  `data_source_url`         TEXT,
  `created_by`              VARCHAR(255)       DEFAULT 'Igor Sas',
  `created_at`              DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`          BIGINT,
  `deleted`                 BOOLEAN            DEFAULT 0,
  `md5_hash`                VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `court_id` (`court_id`),
  INDEX `case_id` (`case_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
