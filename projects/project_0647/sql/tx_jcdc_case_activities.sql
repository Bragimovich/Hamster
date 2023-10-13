create table `tx_jcdc_case_activities`
(
  `id`              INT auto_increment   primary key,
  `court_id`        int,
  `case_id`         VARCHAR (255) DEFAULT NULL,
  `activity_date`   VARCHAR (255) DEFAULT NULL,
  `activity_decs`   VARCHAR (255) DEFAULT NULL,
  `activity_type`   VARCHAR (255) DEFAULT NULL,
  `activity_pdf`    VARCHAR (255) DEFAULT NULL,
  `run_id`          int,
  `deleted`         BOOLEAN DEFAULT 0,
  `data_source_url` VARCHAR (255),
  `created_by`      VARCHAR (255)       DEFAULT 'Habib',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  int,
  `md5_hash` varchar(100),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
