CREATE TABLE `us_ice`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    `title`           VARCHAR(255),
    `teaser`          TEXT,
    `article`         LONGTEXT,
    `date`            DATETIME,
    `link`            VARCHAR(400),
    `city`            VARCHAR(255),
    `state`           VARCHAR(255),
    `creator`         VARCHAR(255)       DEFAULT 'U.S. Immigration and Customs Enforcement',
    `type`            VARCHAR(255)       DEFAULT 'press release',
    `country`         VARCHAR(255)       DEFAULT 'US',
    `data_source_url` VARCHAR(255)       DEFAULT 'https://www.ice.gov/newsroom',
    `with_table`      BOOLEAN            DEFAULT 0,
    `dirty_news`      BOOLEAN            DEFAULT 0,
    `created_by`      VARCHAR(255)       DEFAULT 'Igor Sas',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted`         BOOLEAN            DEFAULT 0,
    UNIQUE KEY `link` (`link`),
    INDEX             `run_id` (`run_id`),
    INDEX             `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
