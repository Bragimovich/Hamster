CREATE TABLE `dc_public_employee_salaries`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `as_of_date`      DATE,
  `agency`          VARCHAR(255),
  `appt_type`       VARCHAR(255),
  `first_name`      VARCHAR(255),
  `last_name`       VARCHAR(255),
  `position_title`  VARCHAR(255),
  `grade`           VARCHAR(255),
  `hire_date`       DATE,
  `annual_salary`   VARCHAR(255),
  `data_source_url` TEXT,
  `page`            INT,
  `created_by`      VARCHAR(255)      DEFAULT 'Ray Piao',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Ray Piao';
