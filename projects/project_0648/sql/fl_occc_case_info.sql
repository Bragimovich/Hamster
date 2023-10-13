create table `fl_occc_case_info`
(
  `id`  int auto_increment   primary key,
  `run_id`  int,
  `court_id`  int,
  `case_id`  varchar (255),
  `case_name`  varchar (512) DEFAULT NULL,
  `case_filed_date`  date DEFAULT NULL,
  `case_type`  varchar (255) DEFAULT NULL,
  `case_description`  varchar (255) DEFAULT NULL,
  `disposition_or_status`  varchar (255) DEFAULT NULL,
  `status_as_of_date`  varchar (255) DEFAULT NULL,
  `judge_name` varchar (255) DEFAULT NULL,
  `deleted`         BOOLEAN           DEFAULT 0,
  `touched_run_id`  int DEFAULT 0,
  `data_source_url`     varchar (350),
  `created_by`           VARCHAR(255)       DEFAULT 'Muhammad Qasim',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash` varchar(100),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
