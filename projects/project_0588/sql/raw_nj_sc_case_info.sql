use us_court_cases;
CREATE TABLE `raw_nj_sc_case_info`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `court_id`                  INT,
  `case_id`                   VARCHAR(255),
  `case_name`                 VARCHAR(255),
  `case_filed_date`           date,
  `case_type`                 VARCHAR(255),
  `case_description`          TEXT,
  `disposition_or_status`     VARCHAR(255),
  `status_as_of_date`         VARCHAR(255),
  `judge_name`                VARCHAR(255),
  `lower_court_id`            INT,
  `lower_case_id`             VARCHAR(255),

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
