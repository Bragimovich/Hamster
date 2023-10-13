CREATE TABLE `nh_sc_case_info`
(
  `id`                    INT AUTO_INCREMENT PRIMARY KEY,
  `run_id`                INT,
  `court_id`              INT,
  `case_id`               VARCHAR(255),
  `case_name`             VARCHAR(512) DEFAULT NULL,
  `case_filed_date`       DATE DEFAULT NULL,
  `case_type`             VARCHAR(255) DEFAULT NULL,
  `case_description`      VARCHAR(255) DEFAULT NULL,
  `disposition_or_status` VARCHAR(255) DEFAULT NULL,
  `status_as_of_date`     VARCHAR(255) DEFAULT NULL,
  `judge_name`            VARCHAR(255) DEFAULT NULL,
  `lower_court_id`        INT,
  `lower_case_id`         VARCHAR(255),
  `data_source_url`       VARCHAR(255),
  `created_by`            VARCHAR(255)      DEFAULT 'Hatri',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Hatri';
