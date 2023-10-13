CREATE TABLE `greenville_case_activities`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `court_id`              varchar(255)                           null,
  `case_id`               varchar(255)                           null,

  `activity_date`    varchar(255)                           null,
  `activity_decs`    text                                   null,
  `activity_type`    varchar(255)                           null,
  `activity_pdf`     varchar(255)                           null,
  `file`             varchar(255)                           null,

  `data_source_url`       varchar(500)                           null,

  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G.',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequency` varchar(255) default 'daily'           null,

  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         tinyint(1)   default 0                 null,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
