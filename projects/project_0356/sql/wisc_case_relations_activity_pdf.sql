CREATE TABLE `wisc_case_relations_activity_pdf`
(
  `id`                            BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `case_activities_md5`           VARCHAR(32)        DEFAULT NULL,
  `case_pdf_on_aws_md5`           VARCHAR(32)        DEFAULT NULL,

  `created_by`                    VARCHAR(255)       DEFAULT 'Eldar Eminov',
  `created_at`                    DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `activities_pdf_on_aws_md5` (`case_activities_md5`, `case_pdf_on_aws_md5`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
