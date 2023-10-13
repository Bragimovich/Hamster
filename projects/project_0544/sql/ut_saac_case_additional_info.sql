create table `ut_saac_case_additional_info`
(
  `id`                          INT auto_increment   primary key,
  `court_id`                    INT,
  `case_id`                     VARCHAR (255),
  `lower_court_name`            VARCHAR (255),
  `lower_case_id`               VARCHAR (255),
  `lower_judge_name`            VARCHAR (255),
  `lower_judgement_date`        date DEFAULT NULL,
  `lower_link`                  VARCHAR (255),
  `disposition`                 VARCHAR (255),
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
