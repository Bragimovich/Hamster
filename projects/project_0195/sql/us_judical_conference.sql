CREATE TABLE `us_judical_conference`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `title`           VARCHAR(255),
  `teaser`          VARCHAR(1020),
  `article`         TEXT,
  `date`            DATETIME,
  `link`            VARCHAR(255),
  `creator`         VARCHAR(255) DEFAULT 'Judicial Conference of the United States',
  `type`            VARCHAR(255) DEFAULT 'press release',
  `country`         VARCHAR(255) DEFAULT 'US',
  `data_source_url` VARCHAR(255) DEFAULT 'https://www.uscourts.gov/judiciary-news',
  `dirty_news`      TINYINT(1) DEFAULT 0,
  `with_table`      TINYINT(1) DEFAULT 0,
  `created_by`      VARCHAR(255)       DEFAULT 'Andrey Tereshchenko',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
