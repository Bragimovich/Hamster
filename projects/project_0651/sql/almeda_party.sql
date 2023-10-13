create table `ca_acsc_case_party`
(
  `id`  int auto_increment   primary key,
  `court_id`  int,
  `case_id`  varchar (255),
  `run_id` int,
  `is_lawyer`  varchar (255),
  `party_name`  varchar (255),
  `party_type`  varchar (255),
  `md5_hash`  varchar (255),
  `touched_run_id` int,
  `law_firm`  varchar (255),
  `deleted` boolean default 0,
  `data_source_url`     varchar (255),
  `created_by`           VARCHAR(255)       DEFAULT 'Mariam',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (md5_hash), 
  INDEX `court_id_idx` (court_id), 
  INDEX `deleted_idx` (deleted)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Mariam Tahir, Task #0651';
