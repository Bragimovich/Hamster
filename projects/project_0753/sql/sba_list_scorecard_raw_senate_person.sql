CREATE TABLE `sba_list_scorecard_raw_senate_person`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `person_id`       int,
  `start_year`      int                  not null,
  `finish_year`     int                  not null,
  `description`     TEXT,
  `data_source_url` VARCHAR(255)      DEFAULT NULL,
  `created_by`      VARCHAR(255)      DEFAULT 'Afia',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255)      GENERATED ALWAYS AS (md5(CONCAT_WS('', CAST(person_id as CHAR), CAST(start_year as CHAR), CAST(finish_year as CHAR), description))) STORED UNIQUE KEY,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci,
COMMENT = 'Created by Afia, Task #753';
