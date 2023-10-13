CREATE TABLE `maac_case_info`
(
    `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                    BIGINT(20),
    `court_id`                  INT,
    `case_id`                   VARCHAR(255),
    `case_name`                 VARCHAR(255),
    `case_filed_date`           DATE,
    `case_type`                 VARCHAR(255),
    `case_description`          VARCHAR(255),
    `disposition_or_status`     VARCHAR(255),
    `status_as_of_date`         VARCHAR(255),
    `judge_name`                VARCHAR(255),
    `link`                      VARCHAR(400),
    `md5_hash`                  VARCHAR(255),
    `country`                   VARCHAR(255)       DEFAULT 'US',
    `data_source_url`           VARCHAR(255)       DEFAULT 'https://www.ma-appellatecourts.org',
    `created_by`                VARCHAR(255)       DEFAULT 'Igor Sas',
    `created_at`                DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted`                   BOOLEAN            DEFAULT 0,
    UNIQUE KEY `md5_hash` (`md5_hash`),
    INDEX             `run_id` (`run_id`),
    INDEX             `court_id` (`court_id`),
    INDEX             `case_id` (`case_id`),
    INDEX             `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
