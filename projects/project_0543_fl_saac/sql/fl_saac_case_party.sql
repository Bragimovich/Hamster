CREATE TABLE us_court_cases.fl_saac_case_party
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `court_id`              int                                  null,
  `case_id`               varchar(255)                         not null,

  `party_name`             varchar(1024)                        null,
  `party_type`             varchar(80)                          null,
  `party_address`          varchar(255)                         null,
  `party_city`             varchar(255)                         null,
  `party_state`            varchar(255)                         null,
  `party_zip`              varchar(255)                         null,
  `party_law_firm`               varchar(255)                         null,
  `party_description`      text                                 null,
  `is_lawyer`              tinyint(1) default 0                 null,

  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`),
  INDEX `case_id` (`case_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Maxim G for scrape task 543';
