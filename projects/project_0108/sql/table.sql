CREATE TABLE `us_epa`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `title`           VARCHAR(255),
  `subtitile`       VARCHAR(255),
  `teaser`          TEXT,
  `article`         LONGTEXT,
  `link`            VARCHAR(255),
  `creator`         VARCHAR(255)       DEFAULT 'US EPA',
  `type`            VARCHAR(255)       DEFAULT 'press release',
  `country`         VARCHAR(255)       DEFAULT  'US',
  `localtion`       VARCHAR(255),
  `date`            DATETIME,
  `contact_info`    VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  UNIQUE KEY `link` (`link`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
