CREATE TABLE `wi_dropout`
(
  `id`            BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`        BIGINT(20),
  `general_id` bigint(20),
  `school_year` varchar(50),
  `subgroup` varchar(255),
  `demographic` varchar(255),
  `student_count`	varchar(255),
  `dropout_count`	varchar(255),
  `completed_term_count`	varchar(255),
  `dropout_rate`	varchar(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'agegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;
