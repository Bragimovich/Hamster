CREATE TABLE `congressional_legislation_committees`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `leg_id`          VARCHAR(255),

  `committee`       VARCHAR(255),
  `date`            DATE,
  `activity`        VARCHAR(255),
  `related`         TEXT,

  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
