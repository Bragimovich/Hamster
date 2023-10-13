CREATE TABLE `maac_case_relations_activity_pdf`
(
    `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `case_activities_md5`       VARCHAR(255),
    `case_pdf_on_aws_md5`       VARCHAR(255),
    `data_source_url`           VARCHAR(255)       DEFAULT 'https://www.ma-appellatecourts.org',
    `created_by`                VARCHAR(255)       DEFAULT 'Igor Sas',
    `created_at`                DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `hash` (`case_activities_md5`, `case_pdf_on_aws_md5`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
