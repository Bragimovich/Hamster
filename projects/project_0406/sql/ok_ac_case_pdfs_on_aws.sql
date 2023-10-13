CREATE TABLE `ok_ac_case_pdfs_on_aws`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `court_id`        INT NULL,
    `case_id`         VARCHAR(255) NULL,
    `source_type`     VARCHAR(255) NULL,
    `aws_link`        VARCHAR(255) NULL,
    `source_link`     VARCHAR(255) NULL,
    `data_source_url` TEXT,
    `created_by`      VARCHAR(255)       DEFAULT 'Alim l.',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id`          BIGINT(20),
    `touched_run_id`  BIGINT,
    `deleted`         BOOLEAN            DEFAULT 0,
    `md5_hash`        VARCHAR(255),
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX             `court_id` (`court_id`),
    INDEX             `case_id` (`case_id`),
    INDEX             `run_id` (`run_id`),
    INDEX             `touched_run_id` (`touched_run_id`),
    INDEX             `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
