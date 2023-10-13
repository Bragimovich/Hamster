CREATE TABLE us_court_cases.vt_sc_case_relations_activity_pdf
(
  `id`  					        int auto_increment   primary key,
  `case_activities_md5` 	VARCHAR(255)       DEFAULT   NULL,
  `case_pdf_on_aws_md5`  	VARCHAR(255)       DEFAULT   NULL,
  `created_by`            VARCHAR(255)       DEFAULT 'Zaid Akram',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  KEY `id` (`id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Zaid Akram, Task #0565';
