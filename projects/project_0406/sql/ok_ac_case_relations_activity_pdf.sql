CREATE TABLE `ok_ac_case_relations_activity_pdf`
(
    `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `case_activities_md5` VARCHAR(255) NULL,
    `case_pdf_on_aws_md5` VARCHAR(255) NULL,
    `data_source_url`     TEXT,
    `created_by`          VARCHAR(255)       DEFAULT 'Alim l.',
    `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id`              BIGINT(20),
    `touched_run_id`      BIGINT,
    `deleted`             BOOLEAN            DEFAULT 0,
    `md5_hash`            VARCHAR(255),
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX                 `run_id` (`run_id`),
    INDEX                 `touched_run_id` (`touched_run_id`),
    INDEX                 `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
