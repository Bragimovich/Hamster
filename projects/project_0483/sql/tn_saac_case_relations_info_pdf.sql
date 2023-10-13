CREATE TABLE `tn_saac_case_relations_info_pdf`
(
  `id`  int auto_increment   primary key,
  `case_info_md5` VARCHAR(255),
  `case_pdf_on_aws_md5`  varchar (255),
  `deleted`                 int DEFAULT 0,
  `created_by`      VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;