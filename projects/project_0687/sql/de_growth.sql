CREATE TABLE `de_growth`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  `general_id`            BIGINT(20),
  `school_year`           varchar(50),
  `race`                  varchar(255),
  `gender`                varchar(255),
  `grade`                 varchar(255),
  `special_demo`          varchar(255),
  `geography`             varchar(255),
  `subgroup`              varchar(255),
  `category`              varchar(255),
  `row_status`            varchar(255),
  `students`              varchar(255),
  `target_met_avg_pct`    varchar(255),
  `data_source_url`       TEXT,
  `created_by`            VARCHAR(255)      DEFAULT 'Hatri',
  `created_at`            DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN           DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Hatri';
