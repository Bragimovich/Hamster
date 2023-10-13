CREATE TABLE `ri_sc_case_additional_info`
(
  `id`                   BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`               BIGINT(20),
  `court_id`             INT,
  `case_id`              VARCHAR(255),
  `lower_court_name`     VARCHAR(255),
  `lower_case_id`        VARCHAR(255),
  `lower_judge_name`     VARCHAR(255),
  `lower_judgement_date` DATE,
  `lower_link`           VARCHAR(255),
  `disposition`          VARCHAR(255),
  `data_source_url`      TEXT,
  `created_by`           VARCHAR(255)      DEFAULT 'Halid Hibragimov',
  `created_at`           DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`       BIGINT,
  `deleted`              BOOLEAN           DEFAULT 0,
  `md5_hash`             VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`),
  INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Halid Hibragimov';
