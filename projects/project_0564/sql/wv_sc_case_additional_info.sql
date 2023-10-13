CREATE TABLE `wv_sc_case_additional_info`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              SMALLINT           DEFAULT NULL,
    `case_id`               VARCHAR(100)       DEFAULT NULL,

    `lower_court_name`           VARCHAR(100)       DEFAULT NULL,
    `lower_case_id`              VARCHAR(100)       DEFAULT NULL,
    `lower_judge_name`           VARCHAR(100)       DEFAULT NULL,
    `lower_link`                 VARCHAR(100)       DEFAULT NULL,
    `lower_judgement_date`       DATETIME           DEFAULT NULL,
    `disposition`                VARCHAR(100)       DEFAULT NULL,

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
