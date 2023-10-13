CREATE TABLE la_assessment_kg_entry (
  `id` 					  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id` 		bigint(20),
  `school_year`               VARCHAR(50),
  `subgroup`                  VARCHAR(255),
  `total_records_submitted`   VARCHAR(255),
  `domain`                    VARCHAR(255),
  `dimension`                 VARCHAR(255),
  `approaching_expectations`         VARCHAR(255),
  `meeting_expectations`             VARCHAR(255),
  `exceeding_expectations`           VARCHAR(255),
  `meeting_exceeding_expectations`   VARCHAR(255),
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
    COMMENT = 'Created by Muhammad Musa, Task #667';
