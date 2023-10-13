create table `sd_sc_case_info`
(
  `id`                    int auto_increment   primary key,
  `run_id`                int,
  `court_id`              int,
  `case_id`               varchar (255),
  `case_name`             text,
  `case_filed_date`       date,
  `case_type`             varchar (255),
  `case_description`      varchar (255),
  `disposition_or_status` text,
  `status_as_of_date`     varchar (255),
  `judge_name`            varchar (255),
  `lower_court_id`        int,
  `lower_case_id`         varchar (255),
  `md5_hash`              varchar (255),
  `data_source_url`       varchar (255),
  `touched_run_id`        BIGINT(20),
  `deleted`               boolean            DEFAULT 0,
  `created_by`            VARCHAR(255)       DEFAULT 'Raza',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX      `run_id` (`run_id`),
  INDEX      `touched_run_id` (`touched_run_id`),
  INDEX      `deleted` (`deleted`),
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #411';
