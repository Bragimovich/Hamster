CREATE TABLE `greenville_case_party`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `court_id`              int                           null,
  `case_id`               varchar(255)                           null,
  `party_name`             varchar(255)                           null,

  `party_type`             varchar(255)                           null,
  `party_law_firm`         varchar(255)                           null,
  `party_address`          varchar(511)                           null,
  `party_city`             varchar(255)                           null,
  `party_state`            varchar(255)                           null,
  `party_zip`              varchar(255)                           null,
  `party_description`      text                                   null,
  `is_lawyer`              tinyint(1)                             null,

  `data_source_url`       varchar(500)                           null,
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G.',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
