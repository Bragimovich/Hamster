create table `oh_sc_case_activities`
(
  `id`  int auto_increment   primary key,
  `court_id`  int,
  `case_id`  varchar (255),
  `run_id` int,
  `activity_date`  date,
  `activity_desc`  mediumtext,
  `activity_type`  varchar  (255) DEFAULT NULL,
  `file`  varchar  (255) DEFAULT NULL,
  `md5_hash`  varchar (255),
  `data_source_url`     varchar (255),
  `created_by`           VARCHAR(255)       DEFAULT 'Raza',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
