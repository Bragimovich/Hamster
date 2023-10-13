CREATE TABLE `greenville_case_info`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `court_id`              varchar(255)                           null,
  `case_id`               varchar(255)                           null,

  `case_name`             varchar(255)                           null,
  `case_filed_date`       varchar(255)                           null,
  `case_description`      text                                   null,
  `case_type`             varchar(255)                           null,
  `disposition_or_status` varchar(255)                           null,
  `status_as_of_date`     varchar(255)                           null,
  `judge_name`            varchar(255)                           null,

  `data_source_url`       varchar(500)                           null,
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G.',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

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
