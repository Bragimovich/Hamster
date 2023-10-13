CREATE TABLE `az_public_employee_salary_temp`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `full_name`                 VARCHAR(255),
  `first_name`                VARCHAR(255),
  `middle_name`               VARCHAR(255),
  `last_name`                 VARCHAR(255),
  `employer`                  VARCHAR(255),
  `job_title`                 VARCHAR(255),
  `department`                VARCHAR(255),
  `department_state_clear`    VARCHAR(255),
  `hire_date`                 DATE,
  `full_time_or_part_time`    VARCHAR(255),
  `annual_pay`                DECIMAL(65,2),
  `hourly_rate`               DECIMAL(65,2),
  `overtime`                  DECIMAL(65,2),
  `created_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `data_source_url`           TEXT,
  `scrape_dev_name`           VARCHAR(255),
  `scrape_frequency`          VARCHAR(255),
  `notes_on_annual_pay`       VARCHAR(255),
  `notes_on_hourly_rate`      VARCHAR(255),
  `other_notes`               VARCHAR(255),
  `last_scrape_date`          DATE,
  `next_scrape_date`          DATE,
  `expected_scrape_frequency` VARCHAR(255),
  `dataset_name_prefix`       VARCHAR(255),
  `scrape_status`             VARCHAR(255),
  `pl_gather_task_id`         BIGINT(20),
  `run_id`                    BIGINT(20),
  `created_by`                VARCHAR(255)      DEFAULT 'Aqeel',
  `touched_run_id`            BIGINT,
  `deleted`                   BOOLEAN DEFAULT FALSE,
  `md5_hash`                  VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
