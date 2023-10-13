CREATE TABLE us_court_cases.vt_sc_case_info
(
    `id`                     BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                 BIGINT(20),
    `court_id`               INT               DEFAULT          NULL,
    `case_id`                VARCHAR(255)                NOT NULL,
    `case_name`              VARCHAR(511)      DEFAULT          NULL,
    `case_filed_date`        DATE              DEFAULT          NULL,
    `case_type`              VARCHAR(255)      DEFAULT          NULL,
    `case_description`       VARCHAR(511)      DEFAULT          NULL,
    `disposition_or_status`  VARCHAR(511)      DEFAULT          NULL,
    `status_as_of_date`      VARCHAR(255)      DEFAULT          NULL,
    `judge_name`             VARCHAR(255)      DEFAULT          NULL,
    `lower_court_id`         INT               DEFAULT          NULL,
    `lower_case_id`          VARCHAR(255)      DEFAULT          NULL,
    `data_source_url`        VARCHAR(255)       DEFAULT 'https://www.vermontjudiciary.org/supreme-court/published-opinions-and-entry-orders',
    `scrape_frequency`       VARCHAR(255)       DEFAULT 'weekly',
    `created_by`             VARCHAR(255)       DEFAULT 'Zaid Akram',
    `created_at`             DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`  BIGINT,
    `deleted`                BOOLEAN            DEFAULT 0,
    `md5_hash`               VARCHAR(255),
	  UNIQUE KEY `md5` (`md5_hash`),
    INDEX `court_id` (`court_id`),
    INDEX `deleted` (`deleted`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    KEY `id` (`id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Zaid Akram, Task #0565';
