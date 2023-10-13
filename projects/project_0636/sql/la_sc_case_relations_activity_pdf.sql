CREATE TABLE `la_sc_case_relations_activity_pdf`
(
  `id`                      int auto_increment primary key,
  `case_activities_md5`     varchar(255)                                null,
  `case_pdf_on_aws_md5`     varchar(255)                                null,
  `created_by`              varchar(255)    default 'Frank Rao'         null,
  `created_at`              datetime        default CURRENT_TIMESTAMP   null,
  `updated_at`              TIMESTAMP       default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
  `run_id`                  bigint                                      null,
  `touched_run_id`          bigint                                      null,
  `deleted`                 tinyint(1)      default 0                   null,
  `md5_hash`                varchar(255)                                null,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  