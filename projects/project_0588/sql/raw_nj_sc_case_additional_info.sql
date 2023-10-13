use us_court_cases;
CREATE TABLE `raw_nj_sc_case_additional_info`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `court_id`                INT,
  `case_id`                 VARCHAR(255),
  `lower_court_name`        VARCHAR(255),
  `lower_case_id`           VARCHAR(255),
  `lower_judge_name`        VARCHAR(255),
  `lower_judgement_date`    date,
  `lower_link`              VARCHAR(255),
  `disposition`             VARCHAR(255),

  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Nj Courts',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  INDEX `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Bhawna Pahadiya';
