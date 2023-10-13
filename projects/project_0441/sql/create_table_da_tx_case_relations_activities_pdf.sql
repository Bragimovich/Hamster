CREATE TABLE `da_tx_case_relations_activity_pdf`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_activity_md5`   VARCHAR(255),
  `case_pdf_on_aws_md5` VARCHAR(255),
  `created_by`      VARCHAR(255)      DEFAULT 'Igor Sas',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  UNIQUE KEY `md5` (`case_activity_md5`, `case_pdf_on_aws_md5`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
