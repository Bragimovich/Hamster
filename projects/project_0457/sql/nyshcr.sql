CREATE TABLE `nyshcr`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    # any columns
    `title`           VARCHAR(600),
    `teaser`          VARCHAR(650),
    `article`         LONGTEXT,
    `creator`         VARCHAR(500)      DEFAULT 'New York State Homes and Community Renewal',
    `date`            DATETIME,
    `link`            VARCHAR(500),
    `type`            VARCHAR(500)      DEFAULT 'press release',
    `data_source_url` VARCHAR(255)               DEFAULT 'https://hcr.ny.gov/pressroom',
    `country`         VARCHAR(255)      DEFAULT 'US',
    `dirty_news`      tinyint(1)        DEFAULT '0',
    `with_table`      tinyint(1)        DEFAULT '0',
    `created_by`      VARCHAR(255)      DEFAULT 'Pospelov Vyacheslav',
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
  COMMENT = 'Script for parsing press_releases (NEW YORK STATE, hcr website)'
  COLLATE = utf8mb4_unicode_520_ci;