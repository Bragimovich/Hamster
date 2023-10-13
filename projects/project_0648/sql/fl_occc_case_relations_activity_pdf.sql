CREATE TABLE `fl_occc_case_relations_activity_pdf`
( 
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          int,
  `case_activities_md5`   varchar(255),
  `case_pdf_on_aws_md5` varchar(255),
  `created_by`      VARCHAR(255)      DEFAULT 'Muhammad Qasim',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  `touched_run_id`  int DEFAULT 0,
  UNIQUE KEY `unique` (`case_activities_md5`, `case_pdf_on_aws_md5`),
  INDEX `deleted` (`deleted`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
