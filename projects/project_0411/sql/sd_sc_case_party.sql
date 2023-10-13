create table `sd_sc_case_party`
(
  `id`                int auto_increment   primary key,
  `court_id`          int,
  `run_id`            int,
  `case_id`           varchar (255),
  `is_lawyer`         varchar (255),
  `party_name`        varchar (255),
  `party_type`        varchar (255),
  `party_law_firm`    varchar (255),
  `party_address`     varchar (255),
  `party_city`        varchar (255),
  `party_state`       varchar (255),
  `party_zip`         varchar (255),
  `party_description` text,
  `md5_hash`          varchar (255),
  `data_source_url`   varchar (255),
  `deleted`           boolean            DEFAULT 0,
  `touched_run_id`    BIGINT(20),
  `created_by`        VARCHAR(255)       DEFAULT 'Raza',
  `created_at`        DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX      `run_id` (`run_id`),
  INDEX      `touched_run_id` (`touched_run_id`),
  INDEX      `deleted` (`deleted`),
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #411';
