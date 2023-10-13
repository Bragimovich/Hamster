CREATE TABLE `pa_ccpbc_case_info`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                  BIGINT(20),
  `court_id`                INT              DEFAULT 102,
  `case_id`                 VARCHAR(255),
  `case_name`               TEXT,
  `case_filed_date`         DATE,
  `case_type`               VARCHAR(255),
  `case_description`        VARCHAR(1023),
  `disposition_or_status`   VARCHAR(255),
  `status_as_of_date`       VARCHAR(255),
  `judge_name`              VARCHAR(255),
  `data_source_url`         VARCHAR(255),
  `created_by`              VARCHAR(255)      DEFAULT 'Raza',
  `created_at`              DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`                 BOOLEAN           DEFAULT 0,
  `touched_run_id`          BIGINT(20),
  `md5_hash`                VARCHAR (255)     DEFAULT NULL,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #650';
