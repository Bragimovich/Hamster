CREATE TABLE `il_mchenry__charges`
(
  `id`                         BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrest_id`                  BIGINT(20),
  `number`                     INT DEFAULT NULL,
  `description`                VARCHAR(255) DEFAULT NULL,
  `offense_date`               DATE,
  `offense_time`               TIME,
  `crime_class`                VARCHAR(255) DEFAULT NULL,
  `attempt_or_commit`          VARCHAR(255) DEFAULT NULL,
  `disposition`                VARCHAR(255) DEFAULT NULL,
  `disposition_date`           DATE,
  `docket_number`              VARCHAR(255) DEFAULT NULL,
  `sentence_date`              DATE,
  `sentence_length`            VARCHAR(255) DEFAULT NULL,
  `arresting_agency`           VARCHAR(255) DEFAULT NULL,
  `data_source_url`            VARCHAR(255) DEFAULT NULL,
  `created_by`                 VARCHAR(255)       DEFAULT 'Dmitry Suschinsky',
  `created_at`                 DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                     BIGINT DEFAULT NULL,
  `touched_run_id`             BIGINT DEFAULT NULL,
  `deleted`                    BOOLEAN            DEFAULT 0,
  `md5_hash`                   VARCHAR(255),
  INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
