CREATE TABLE us_court_cases.vt_sc_case_party
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              INT               DEFAULT          NULL,
    `case_id`               VARCHAR(255)                NOT NULL,
    `is_lawyer`             BOOLEAN,
    `party_name`            VARCHAR(255)      DEFAULT          NULL,
    `party_type`            VARCHAR(255)      DEFAULT          NULL,
    `party_law_firm`        VARCHAR(511)      DEFAULT          NULL,
    `party_address`         VARCHAR(511)      DEFAULT          NULL,
    `party_city`            VARCHAR(255)      DEFAULT          NULL,
    `party_state`           VARCHAR(255)      DEFAULT          NULL,
    `party_zip`             VARCHAR(255)      DEFAULT          NULL,
    `party_description`     TEXT,
    `data_source_url`       VARCHAR(255)       DEFAULT 'https://www.vermontjudiciary.org/supreme-court/published-opinions-and-entry-orders',
    `created_by`            VARCHAR(255)       DEFAULT 'Zaid Akram',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`  BIGINT,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(255),
	  UNIQUE KEY `md5` (`md5_hash`),
    INDEX `court_id` (`court_id`),
    INDEX `deleted` (`deleted`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    KEY `id` (`id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Zaid Akram, Task #0565';
