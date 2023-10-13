CREATE TABLE `pa_pc_case_relations_info_pdf`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_info_md5`         VARCHAR(32)        DEFAULT NULL,
  `case_pdf_on_aws_md5`   VARCHAR(32)        DEFAULT NULL,
  `created_by`            VARCHAR(20)        DEFAULT 'Eldar Eminov',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`case_info_md5`, `case_pdf_on_aws_md5`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
