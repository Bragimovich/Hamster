CREATE TABLE `wv_sc_case_pdfs_on_aws`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              SMALLINT           DEFAULT NULL,
    `case_id`               VARCHAR(100)       DEFAULT NULL,

    `source_type`           VARCHAR(100)       DEFAULT NULL,
    `aws_link`              VARCHAR(255)       DEFAULT NULL,
    `source_link`           VARCHAR(255)       DEFAULT NULL,
    `aws_html_link`         VARCHAR(255)       DEFAULT NULL,

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
