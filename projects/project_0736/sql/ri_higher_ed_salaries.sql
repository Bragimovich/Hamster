CREATE TABLE ri_higher_ed_salaries (
  `id` 					BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `fiscal_year`  int,
  `first_name`  VARCHAR(255),
  `middle_name`  VARCHAR(255),
  `last_name`  VARCHAR(255),
  `department`  VARCHAR(255),
  `title`  VARCHAR(255),
  `regular_earnings`  VARCHAR(255),
  `overtime_earnings`  VARCHAR(255),
  `other_earnings`  VARCHAR(255),
  `total_earnings`  VARCHAR(255),
  `annual_salary`  VARCHAR(255),
  `termination`  date,
  `data_source_url` 	VARCHAR(255),
  `created_by`     		VARCHAR(255)      DEFAULT 'Muhammad Musa',
  `created_at`      	DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          	BIGINT(20),
  `touched_run_id`  	BIGINT(20),
  `deleted`         	BOOLEAN           DEFAULT 0,
  `md5_hash`        	VARCHAR(255),
  UNIQUE KEY        	`md5` (`md5_hash`),
  INDEX             	`run_id` (`run_id`),
  INDEX             	`touched_run_id` (`touched_run_id`),
  INDEX             	`deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Muhammad Musa, Task #736';
