CREATE TABLE `nh_sc_case_activities`
(
  `id`                    INT AUTO_INCREMENT PRIMARY KEY,
  `run_id`                INT,
  `court_id`              INT,
  `case_id`               VARCHAR(255),
  `activity_date`         DATETIME          DEFAULT NULL,
  `activity_desc`         VARCHAR(255),
  `activity_type`         VARCHAR(255),
  `file`                  VARCHAR(255),
  `data_source_url`       VARCHAR(255),
  `created_by`            VARCHAR(255)      DEFAULT 'Hatri',
  `created_at`            DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  `touched_run_id`        BIGINT,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Hatri';
