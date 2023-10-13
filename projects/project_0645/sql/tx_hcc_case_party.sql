create table `tx_hcc_case_party`
(
  `id`                  int auto_increment   primary key,
  `run_id`              int,
  `court_id`            int               DEFAULT 88,
  `case_id`             varchar (255),
  `is_lawyer`           int,
  `party_name`          varchar (255)      DEFAULT NULL,
  `party_type`          varchar (255)      DEFAULT NULL,
  `law_firm`      varchar (255)      DEFAULT NULL,
  `party_address`       varchar (255)      DEFAULT NULL,
  `party_city`          varchar (255)      DEFAULT NULL,
  `party_state`         varchar (255)      DEFAULT NULL,
  `party_zip`           varchar (255)      DEFAULT NULL,
  `party_description`   text               DEFAULT NULL,
  `touched_run_id`      int,
  `md5_hash`            VARCHAR(255)       DEFAULT NULL,
  `data_source_url`     varchar (255)      DEFAULT "https://www.cclerk.hctx.net/applications/websearch/CourtSearch.aspx?CaseType=Civil",
  `deleted`             BOOLEAN            DEFAULT 0,
  `created_by`          VARCHAR(255)       DEFAULT 'Azeem',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
