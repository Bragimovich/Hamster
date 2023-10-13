CREATE TABLE us_court_cases.fl_saac_case_parties_raw
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `court_id`      int,
    `party_id`      bigint(20),
    `party_last_name`   VARCHAR(255),
    `party_first_name`  VARCHAR(255),
    `party_middle_name` VARCHAR(255),

    `party_type`    VARCHAR(255),

    `party_link`    VARCHAR(255),
    `party_address` VARCHAR(255),
    `party_phone`   VARCHAR(255),
    `case_counter`  int,
  `done`     boolean,
  `data_source_url` VARCHAR(255) DEFAULT 'http://onlinedocketsdca.flcourts.org/',
  `created_by`      VARCHAR(255)      DEFAULT 'Maxim G',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `done` (`done`),
  INDEX `party_id` (`party_id`),
  INDEX `court_id` (`court_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by ';
