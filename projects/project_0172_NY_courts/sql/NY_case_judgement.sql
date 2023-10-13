CREATE TABLE us_court_cases.NY_case_judgement
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `case_id`                     VARCHAR(255)                        not null,
  `court_id`                    int                                 null,
  `requested_amount`            VARCHAR(255) DEFAULT '',
  `judgement_amount`            VARCHAR(255) DEFAULT '',
  `judgement_date`              DATE,
  `filed_date`                  DATE,
  `judgement_document_url`      VARCHAR(255) DEFAULT '',
  `judgement_document_aws`      VARCHAR(255) null,


  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
