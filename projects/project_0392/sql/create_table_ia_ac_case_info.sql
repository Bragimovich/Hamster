CREATE TABLE `ia_ac_case_info`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `court_id`        INT,
  `case_id`         VARCHAR(255),
  `case_name`       TEXT,
  `case_filed_date` DATE,
  `case_type`       VARCHAR(255),
  `case_description`      TEXT,
  `disposition_or_status` VARCHAR(255),
  `status_as_of_date`     VARCHAR(255),
  `judge_name`            VARCHAR(500),
  `link`                  TEXT,
  `data_source_url` TEXT               DEFAULT 'https://www.iowacourts.state.ia.us/ESAWebApp/AppelAdvFrame',
  `created_by`      VARCHAR(255)       DEFAULT 'Igor Sas',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX             `court_id` (`court_id`),
  INDEX             `case_id` (`case_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
