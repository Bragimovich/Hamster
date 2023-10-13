create table `fl_occc_case_activities`
(
  `id`              INT auto_increment   primary key,
  `run_id`          int,
  `court_id`        int,
  `case_id`         VARCHAR (255),
  `activity_date`   date,
  `activity_decs`   MEDIUMTEXT,
  `activity_type`   VARCHAR (255),
  `activity_pdf`    VARCHAR (255),
  `deleted`         BOOLEAN           DEFAULT 0,
  `touched_run_id`  int DEFAULT 0,
  `data_source_url` VARCHAR (255),
  `created_by`      VARCHAR (255)       DEFAULT 'Muhammad Qasim',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash` varchar(100),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
