CREATE TABLE `university_of_vermont_origin`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`            BIGINT(20),
  `name`              VARCHAR(255),
  `primary_job_title` VARCHAR(255),
  `base_pay`          VARCHAR(255),
  `salary_data`       VARCHAR(255),
  `data_source_url`   VARCHAR(500),
  `created_by`        VARCHAR(255)      DEFAULT 'Halid Ibragimov',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(255),# GENERATED ALWAYS AS (md5(CONCAT_WS('', name, primary_job_title, base_pay, salary_data))
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
)
DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = '';
