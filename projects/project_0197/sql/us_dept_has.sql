CREATE TABLE `us_dept_has`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `title`           VARCHAR(2048),
  `teaser`          LONGTEXT,
  `arcticle`        TEXT,
  `link`            VARCHAR(1028) UNIQUE,
  `creator`         VARCHAR(1028)      DEFAULT 'US Department of HCA',
  `type`            VARCHAR(255)       DEFAULT 'press release',
  `country`         VARCHAR(255)       DEFAULT 'US',
  `date`            DATETIME,
  `dirty_news`      tinyint(1),
  `with_table`      tinyint(1),
  `data_source_url` VARCHAR(255)              DEFAULT 'https://appropriations.house.gov/news/homeland-security-press-releases',
  `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
