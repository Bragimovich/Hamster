create table `mn_saac_case_pdfs_on_aws`
(
  `id`  int auto_increment   primary key,
  `run_id`  int,
  `case_id`  varchar (255),
  `court_id`  int,
  `source_type`  varchar (255),
  `aws_html_link` varchar (255),
  `aws_link` varchar (255),
  `source_link` varchar (255),
  `data_source_url` varchar (350),
  `md5_hash`  varchar (255),
  `deleted` int DEFAULT 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Tauseeq',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
