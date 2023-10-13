CREATE TABLE `wv_sc_case_relations_activity_pdf`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `case_info_md5`       VARCHAR(32) DEFAULT NULL,
    `case_pdf_on_aws_md5` VARCHAR(32) DEFAULT NULL,

    `data_source_url`       VARCHAR(255)       DEFAULT NULL,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(32)        DEFAULT NULL,
    `created_by`            VARCHAR(20)        DEFAULT 'Farzpal Singh',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `md5_info_aws` (`case_info_md5`, `case_pdf_on_aws_md5`)
    INDEX `deleted` (`deleted`),
    INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Farzpal Singh, Task #0564';
