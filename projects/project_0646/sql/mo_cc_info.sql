CREATE TABLE `mo_cc_case_info`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`                INT             DEFAULT 91,
  `case_id`                 VARCHAR(255)    NOT NULL,
  `case_name`               VARCHAR(255)    NOT NULL,
  `case_filed_date`         DATE,
  `case_type`               VARCHAR(255),
  `case_description`        VARCHAR(255),
  `disposition_or_status`   VARCHAR(255),
  `status_as_of_date`       VARCHAR(255),
  `judge_name`              VARCHAR(255),
  `run_id`                  BIGINT(20),
  `data_source_url`         VARCHAR(255) DEFAULT 'https://www.courts.mo.gov/casenet/cases/filingDateSearch.do',
  `created_by`              VARCHAR(255)   DEFAULT 'Umar',
  `created_at`              DATETIME       DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`          BIGINT(20),
  `deleted`                 BOOLEAN        DEFAULT 0,
  `md5_hash`                VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
