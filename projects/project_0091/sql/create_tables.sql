CREATE TABLE `ohio_state_employee_salaries`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `name`               	VARCHAR(255),
    `job_title`             VARCHAR(255),
    `agency`             	VARCHAR(255),
    `max_hourly_rate`       DECIMAL(10,2),
    `amount`             	DECIMAL(10,2),
    `year`					year,
    `data_source_url`        TEXT,
    `scrape_frequency`       VARCHAR(255)       DEFAULT 'monthly',
    `created_by`             VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`             DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`run_id`                 BIGINT(20),
    `touched_run_id`         BIGINT,
    `deleted`                BOOLEAN            DEFAULT 0,
    `md5_hash`               VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #91';
  
  
CREATE TABLE IF NOT EXISTS `ohio_state_employee_salaries_runs` 
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Linnik Victor',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
	COMMENT = 'Created by Victor Linnik, Task #91';
