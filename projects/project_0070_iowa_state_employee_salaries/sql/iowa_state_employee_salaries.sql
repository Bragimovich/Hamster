CREATE TABLE `iowa_state_employee_salaries`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `year` INT,
  `name` VARCHAR(255),
  `gender` VARCHAR(50),
  `agency` VARCHAR(255),
  `city_county` VARCHAR(255),
  `classification` VARCHAR(255),
  `base_pay_end_of_fy` VARCHAR(255),
  `annual_gross_pay` VARCHAR(255),
  `travel` VARCHAR(255),
  `data_source_url` TEXT,
  `scrape_frequency` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
