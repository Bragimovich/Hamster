create table `az_aac2_case_relations_info_pdf`
(
  `id`  int auto_increment   primary key,
  `run_id`  int,
  `case_info_md5`  varchar (255),
  `case_pdf_on_aws_md5`  varchar (255),
  `deleted` int DEFAULT 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Raza',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`case_info_md5`,`case_pdf_on_aws_md5`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
