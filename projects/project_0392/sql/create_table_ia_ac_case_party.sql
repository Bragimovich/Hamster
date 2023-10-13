CREATE TABLE `ia_ac_case_party`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`        INT,
  `case_id`         VARCHAR(255),
  `is_lawyer`       INT,
  `party_name`      VARCHAR(255),
  `party_type`      VARCHAR(255),
  `party_law_firm`  VARCHAR(255),
  `party_address`   VARCHAR(255),
  `party_city`      VARCHAR(255),
  `party_state`     VARCHAR(255),
  `party_zip`       VARCHAR(255),
  `party_description`       TEXT,
  `data_source_url`                    TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Igor Sas',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX             `court_id` (`court_id`),
  INDEX             `case_id` (`case_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
