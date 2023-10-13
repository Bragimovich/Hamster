CREATE TABLE us_court_cases.vt_sc_case_activities
(
    `id`               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`           BIGINT(20),
    `court_id`         INT                DEFAULT       NULL,
    `case_id`          VARCHAR(255)                     NOT NULL,
    `activity_date`    DATE                             NULL,
    `activity_desc`    MEDIUMTEXT         DEFAULT       NULL,
    `activity_type`    VARCHAR(255)       DEFAULT       NULL,
    `file`             VARCHAR(511),
    `data_source_url`  VARCHAR(255)       DEFAULT 'https://www.vermontjudiciary.org/supreme-court/published-opinions-and-entry-orders',
    `created_by`       VARCHAR(255)       DEFAULT 'Zaid Akram',
    `created_at`       DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`  BIGINT,
    `deleted`          BOOLEAN            DEFAULT 0,
    `md5_hash`         VARCHAR(255),
	  UNIQUE KEY `md5` (`md5_hash`),
    INDEX `court_id` (`court_id`),
    INDEX `deleted` (`deleted`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    KEY `id` (`id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Zaid Akram, Task #0565';
