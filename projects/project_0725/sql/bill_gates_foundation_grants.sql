CREATE TABLE `bill_gates_foundation_grants`
(
  `id`               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`           BIGINT(20),
  `grant_id`         VARCHAR(50),
  `grantee`          VARCHAR(255),
  `purpose`          VARCHAR(500),
  `division`         VARCHAR(255),
  `date_committed`   VARCHAR(50),
  `duration_months`  VARCHAR(50),
  `amount_committed` VARCHAR(50),
  `grantee_website`  VARCHAR(50),
  `grantee_city`     VARCHAR(50),
  `grantee_state`    VARCHAR(50),
  `grantee_country`  VARCHAR(50),
  `region_served`    VARCHAR(50),
  `topic`            VARCHAR(50),
  `data_source_url`  TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Hatri',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Hatri';
