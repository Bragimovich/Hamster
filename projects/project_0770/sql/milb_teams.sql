CREATE TABLE `milb_teams`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `mlb_id`          BIGINT,
  `team_name`       VARCHAR(255),
  `team_abbr`       VARCHAR(255),
  `level`           VARCHAR(255),
  `mlb_team`        VARCHAR(255),
  `mlb_division`    VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Ray Piao',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Ray Piao';
