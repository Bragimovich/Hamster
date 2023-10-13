create table `il_cccc_case_info`
(
  `id`                      int auto_increment primary key,
  `court_id`                int                                         null,
  `case_id`                 varchar(255)                                null,
  `case_name`               text                                        null,
  `case_filed_date`         date                                        null,
  `case_type`               varchar(255)                                null,
  `case_description`        varchar(255)                                null,
  `disposition_or_status`   varchar(255)                                null,
  `status_as_of_date`       varchar(255)                                null,
  `judge_name`              varchar(255)                                null,
  `data_source_url`         varchar(255)                                null,
  `created_by`              varchar(255)    default 'Abdul Wahab'       null,
  `created_at`              datetime        default CURRENT_TIMESTAMP   null,
  `updated_at`              TIMESTAMP       default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
  `run_id`                  bigint                                      null,
  `touched_run_id`          bigint                                      null,
  `deleted`                 tinyint(1)      default 0                   null,
  `md5_hash`                varchar(255)                                null,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `run_id` (`run_id`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
