CREATE TABLE `ca_kcsc_case_relations_activity_pdf`
(
  `id`                  int auto_increment   primary key,
  `court_id`            VARCHAR (255),
  `case_activities_md5` VARCHAR (255),
  `case_pdf_on_aws_md5` varchar (255),
  `deleted`             tinyint (1) DEFAULT 0,
  `created_by`          VARCHAR (255)       DEFAULT 'Asim saeed',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`            VARCHAR (255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Asim Saeed, Task #0644';
