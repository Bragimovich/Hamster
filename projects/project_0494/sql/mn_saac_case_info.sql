create table `mn_saac_case_info`
(
  `id`  int auto_increment   primary key,
  `run_id`  int,
  `court_id`  int,
  `case_id`  varchar (255),
  `case_filed_date`  date DEFAULT NULL,
  `case_name`  varchar (255) DEFAULT NULL,
  `case_type`  varchar (255) DEFAULT NULL,
  `case_description`  varchar (255) DEFAULT NULL,
  `disposition_or_status`  varchar (255) DEFAULT NULL,
  `status_as_of_date`  varchar (255) DEFAULT NULL,
  `judge_name` varchar (255) DEFAULT NULL,
  `md5_hash`  varchar (255),
  `deleted` int DEFAULT 0,
  `data_source_url`     varchar (350),
  `created_by`           VARCHAR(255)       DEFAULT 'Tauseeq',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
