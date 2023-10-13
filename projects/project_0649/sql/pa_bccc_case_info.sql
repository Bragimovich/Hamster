create table `pa_bccc_case_info`
(
  `id`                      int auto_increment   primary key,
  `court_id`                int,
  `case_id`                 varchar (255),
  `case_name`               varchar(511),
  `case_filed_date`         date,
  `case_type`               varchar (255),
  `case_description`        varchar (255),
  `disposition_or_status`   varchar (255),
  `status_as_of_date`       varchar (255),
  `judge_name`              varchar (255),
  `lower_court_id`          smallint(6),
  `lower_case_id`           varchar (255),
  `md5_hash`                varchar (255),
  `run_id`                  int,
  `touched_run_id`           BIGINT(20),
  `deleted`                 tinyint(6) DEFAULT 0,
  `data_source_url`         varchar (255),
  `created_by`              varchar (255)       DEFAULT 'M Musa',
  `created_at`              DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by M Musa 649';
