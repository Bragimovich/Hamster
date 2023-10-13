CREATE TABLE `ok_ac_case_info`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `court_id`              INT NULL,
    `case_id`               VARCHAR(255) NULL,
    `case_name`             TEXT NULL,
    `case_filed_date`       DATE NULL,
    `case_type`             VARCHAR(255) NULL,
    `case_description`      VARCHAR(255) NULL,
    `disposition_or_status` VARCHAR(255) NULL,
    `status_as_of_date`     VARCHAR(255) NULL,
    `judge_name`            VARCHAR(255) NULL,
    `lower_court_id`        INT NULL,
    `lower_case_id`         VARCHAR(255) NULL,
    `data_source_url`       TEXT,
    `created_by`            VARCHAR(255)       DEFAULT 'Alim l.',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id`                BIGINT(20),
    `touched_run_id`        BIGINT,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(255),
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX                   `court_id` (`court_id`),
    INDEX                   `case_id` (`case_id`),
    INDEX                   `run_id` (`run_id`),
    INDEX                   `touched_run_id` (`touched_run_id`),
    INDEX                   `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
