CREATE TABLE `il_dupage__arrestee_addresses`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id`     BIGINT                                 NULL,
  `full_address`    VARCHAR(255)                           NULL,
  `street_address`  VARCHAR(255)                           NULL,
  `unit_number`     VARCHAR(255)                           NULL,
  `city`            VARCHAR(255)                           NULL,
  `county`          VARCHAR(255)                           NULL,
  `state`           VARCHAR(255)                           NULL,
  `zip`             VARCHAR(255)                           NULL,
  `lan`             VARCHAR(255)                           NULL,
  `lon`             VARCHAR(255)                           NULL,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Scraper name',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY        `md5` (`md5_hash`),
  INDEX             `run_id` (`run_id`),
  INDEX             `touched_run_id` (`touched_run_id`),
  INDEX             `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Alim L.';
