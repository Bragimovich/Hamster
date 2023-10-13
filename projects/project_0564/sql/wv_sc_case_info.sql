CREATE TABLE `wv_sc_case_info`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              SMALLINT           DEFAULT NULL,
    `case_id`               VARCHAR(100)       DEFAULT NULL,

    `case_name`             VARCHAR(100)       DEFAULT NULL,
    `case_type`             VARCHAR(100)       DEFAULT NULL,
    `case_filed_date`       DATETIME           DEFAULT NULL,
    `case_description`      VARCHAR(1000)      DEFAULT NULL,
    `disposition_or_status` VARCHAR(100)       DEFAULT NULL,
    `status_as_of_date`     VARCHAR(100)       DEFAULT NULL,
    `judge_name`            VARCHAR(100)       DEFAULT NULL,
    `lower_court_id`        SMALLINT           DEFAULT NULL,
    `lower_case_id`         VARCHAR(100)       DEFAULT NULL,

    `data_source_url`       VARCHAR(255)       DEFAULT NULL,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(32)        DEFAULT NULL,
    `created_by`            VARCHAR(20)        DEFAULT 'Farzpal Singh',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `md5_hash` (`md5_hash`)
    INDEX `court_id` (`court_id`),
    INDEX `deleted` (`deleted`),
    INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Farzpal Singh, Task #0564';
