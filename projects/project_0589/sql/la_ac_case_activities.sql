create table `la_2c_ac_case_activities`
(
  `id`              INT auto_increment   primary key,
  `court_id`        int,
  `case_id`         VARCHAR (255),
  `activity_date`   VARCHAR (255),
  `activity_desc`   VARCHAR (255),
  `activity_type`   VARCHAR (255),
  `run_id`          int,
  `deleted`         int DEFAULT 0,
  `data_source_url` VARCHAR (255),
  `created_by`      VARCHAR (255)       DEFAULT 'Tauseeq',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  int,
  `md5_hash` varchar(100),
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
