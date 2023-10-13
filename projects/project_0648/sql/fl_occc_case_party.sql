create table `fl_occc_case_party`
(
  `id`  int auto_increment   primary key,
  `run_id`  int,
  `court_id`  int, 
  `case_id`  varchar (255),
  `is_lawyer`  BOOLEAN           DEFAULT 0,
  `party_name`  MEDIUMTEXT DEFAULT NULL,
  `party_type`  varchar (255) DEFAULT NULL,
  `law_firm` varchar (255) DEFAULT NULL,
  `party_address` varchar (255) DEFAULT NULL,
  `party_city` varchar (255) DEFAULT NULL,
  `party_state` varchar (255) DEFAULT NULL,
  `party_zip` varchar (255) DEFAULT NULL,
  `party_description` TEXT  DEFAULT NULL, 
  `data_source_url` varchar (350),
  `deleted`         BOOLEAN           DEFAULT 0,
  `touched_run_id`  int DEFAULT 0,
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
