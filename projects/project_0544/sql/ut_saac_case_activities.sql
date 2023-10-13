create table `ut_saac_case_activities`
(
  `id`                          INT auto_increment   primary key,
  `court_id`                    int,
  `case_id`                     VARCHAR (255),
  `activity_date`               DATE        DEFAULT NULL,
  `activity_desc`               mediumtext,
  `activity_type`               VARCHAR (255),
  `file`                        VARCHAR (255) DEFAULT NULL,
  `run_id`                      int,
  `deleted`                     BOOLEAN DEFAULT 0,
  `touched_run_id`              int,
  `md5_hash`                    VARCHAR(255) DEFAULT NULL,
  `data_source_url`             VARCHAR (255),
  `created_by`                  VARCHAR (255)       DEFAULT 'Raza',
  `created_at`                  DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
