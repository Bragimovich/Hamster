CREATE TABLE `ny_absenteeism`
(
  `id` BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id` BIGINT(20),
  `general_id`  bigint(20),
  school_year VARCHAR(50),
  subject VARCHAR(255),
  subgroup VARCHAR(255),
  enrollment VARCHAR(255),
  absent_count VARCHAR(255),
  absent_rate VARCHAR(255),
  level VARCHAR(255),
  override VARCHAR(255),
  `data_source_url` TEXT,
  `created_by` VARCHAR(255) DEFAULT 'Hassan',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id` BIGINT,
  `deleted` BOOLEAN DEFAULT 0,
  `md5_hash` VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
