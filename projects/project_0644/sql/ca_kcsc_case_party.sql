create table `ca_kcsc_case_party`
(
  `id`                   int auto_increment   primary key,
  `court_id`             int,
  `case_id`              varchar (255),
  `is_lawyer`            tinyint (1) DEFAULT 0,
  `party_name`           varchar (255),
  `party_type`           varchar (255),
  `law_firm`             varchar (255),
  `party_address`        varchar (255),
  `party_city`           varchar (255),
  `party_state`          varchar (255),
  `party_zip`            varchar (255),
  `party_description`    text,
  `md5_hash`             varchar (255),
  `run_id`               int,
  `touched_run_id`       BIGINT,
  `dara_source_url`      varchar (255),
  `created_by`           varchar (255)       DEFAULT 'Asim Saeed',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Asim Saeed, Task #0644';
