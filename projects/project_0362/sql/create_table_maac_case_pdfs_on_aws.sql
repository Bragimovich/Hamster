CREATE TABLE `maac_case_pdfs_on_aws`
(
    `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `court_id`                  INT,
    `case_id`                   VARCHAR(255),
    `source_type`               VARCHAR(255),
    `aws_link`                  VARCHAR(500),
    `source_link`               VARCHAR(500),
    `md5_hash`                  VARCHAR(255),
    `created_by`                VARCHAR(255)       DEFAULT 'Igor Sas',
    `created_at`                DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted`                   BOOLEAN            DEFAULT 0,
    UNIQUE KEY `md5_hash` (`md5_hash`),
    INDEX             `court_id` (`court_id`),
    INDEX             `case_id` (`case_id`),
    INDEX             `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
