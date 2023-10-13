create table `ut_saac_case_party`
(
  `id`                  int auto_increment   primary key,
  `run_id`              int,
  `court_id`            int,
  `case_id`             varchar (255),
  `is_lawyer`           BOOLEAN,
  `party_name`          varchar (255) DEFAULT NULL,
  `party_type`          varchar (255) DEFAULT NULL,
  `party_law_firm`      varchar (255) DEFAULT NULL,
  `party_address`       varchar (255) DEFAULT NULL,
  `party_city`          varchar (255) DEFAULT NULL,
  `party_state`         varchar (255) DEFAULT NULL,
  `party_zip`           varchar (255) DEFAULT NULL,
  `party_description`   text DEFAULT NULL,
  `md5_hash`            VARCHAR(255) DEFAULT NULL,
  `data_source_url`     varchar (350),
  `deleted`             BOOLEAN DEFAULT 0,
  `touched_run_id`      int,
  `created_by`          VARCHAR(255)       DEFAULT 'Raza',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
