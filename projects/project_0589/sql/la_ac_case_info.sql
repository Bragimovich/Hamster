create table `la_2c_ac_case_info`
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
  `lower_court_id`  int,
  `lower_case_id`  varchar (255),
  `deleted` int DEFAULT 0,
  `data_source_url`     varchar (350),
  `created_by`           VARCHAR(255)       DEFAULT 'Tauseeq',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  int,
  `md5_hash` varchar(100),
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
