CREATE TABLE `co_denver_court_hearings`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20) NULL DEFAULT NULL,
  # any columns
  
  `charge_id` BIGINT(20) NULL DEFAULT NULL,
  `court_name` VARCHAR(255) NULL DEFAULT NULL,
  `court_date` DATE NULL DEFAULT NULL,
  `court_time` TIME NULL DEFAULT NULL,
  `court_room` VARCHAR(255) NULL DEFAULT NULL,
  `case_number` VARCHAR(255) NULL DEFAULT NULL,
  `case_type` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by`      VARCHAR(255)      DEFAULT 'Mashal',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT NULL DEFAULT NULL,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255) NULL DEFAULT NULL,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Mashal';
