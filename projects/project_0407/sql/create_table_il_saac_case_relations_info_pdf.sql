CREATE TABLE `il_saac_case_relations_info_pdf`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_info_md5`     VARCHAR(255),
  `case_pdf_on_aws_md5`     VARCHAR(255),
  `created_by`              VARCHAR(255)       DEFAULT 'Igor Sas',
  `created_at`              DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`                 BOOLEAN            DEFAULT 0,
  `md5_hash`                VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
