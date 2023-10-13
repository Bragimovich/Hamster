create table `ga_ac_case_info `
(
  `id`  int auto_increment   primary key,
  `court_id`  int,
  `case_id`  varchar (255),
  `run_id`    BIGINT(20),
  `case_name`  text,
  `case_filed_date`  date,
  `case_type`  varchar (255),
  `case_description`  varchar (255),
  `disposition_or_status`  varchar (255),
  `status_as_of_date`  varchar (255),
  `judge_name`  varchar (255),
  `lower_court_id`  int,
  `lower_case_id`  varchar (255),
  `md5_hash`  varchar (255),
  `touched_run_id`  int DEFAULT NULL,
  `data_source_url`     varchar (255)   DEFAULT 0,
  `deleted`             boolean          DEFAULT 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
