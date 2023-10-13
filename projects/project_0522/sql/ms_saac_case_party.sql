create table `ms_saac_case_party`
(
  `id`                      int auto_increment primary key,
  `court_id`                int                                         null,
  `case_id`                 varchar(255)                                null,
  `is_lawyer`               varchar(255)                                null,
  `party_name`              varchar(255)                                null,
  `party_type`              varchar(255)                                null,
  `party_law_firm`          varchar(255)                                null,
  `party_address`           varchar(255)                                null,
  `party_city`              varchar(255)                                null,
  `party_state`             varchar(255)                                null,
  `party_zip`               varchar(255)                                null,
  `party_description`       text                                        null,
  `data_source_url`         varchar(255)                                null,
  `created_by`              varchar(255)    default 'Aglazkov'           null,
  `created_at`              datetime        default CURRENT_TIMESTAMP   null,
  `updated_at`              TIMESTAMP       default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
  `run_id`                  bigint                                      null,
  `touched_run_id`          bigint                                      null,
  `deleted`                 tinyint(1)      default 0                   null,
  `md5_hash`                varchar(255)                                null,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;