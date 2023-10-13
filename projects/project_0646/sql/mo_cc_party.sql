CREATE TABLE `mo_cc_case_party`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`        INT               NOT NULL DEFAULT 91,
  `case_id`         VARCHAR(255)      NOT NULL,
  `is_lawyer`       BOOLEAN           DEFAULT 0,
  `party_name`      VARCHAR(255)      NOT NULL,
  `party_type`      VARCHAR(255),
  `law_firm`        VARCHAR(255),
  `party_address`   VARCHAR(255),
  `party_city`      VARCHAR(255),
  `party_state`     VARCHAR(255),
  `party_zip`       VARCHAR(255),
  `party_description` TEXT,
  `run_id`          BIGINT(20),
  `data_source_url` VARCHAR(255) DEFAULT 'https://www.courts.mo.gov/casenet/cases/filingDateSearch.do',
  `created_by`      VARCHAR(255)      DEFAULT 'Umar',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
