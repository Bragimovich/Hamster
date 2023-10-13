CREATE TABLE `us_gsa`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    `title`           VARCHAR(255),
    `teaser`          TEXT,
    `article`         LONGTEXT,
    `link`            VARCHAR(255),
    `creator`         VARCHAR(255)       DEFAULT 'General Services Administration',
    `country`         VARCHAR(255)       DEFAULT 'US',
    `type`            VARCHAR(255)       DEFAULT 'press release',
    `city`            VARCHAR(255),
    `state`           VARCHAR(255),
    `date`            DATE,
    `data_source_url` VARCHAR(255)       DEFAULT 'https://www.gsa.gov/about-us/newsroom/news-releases/',
    `created_by`      VARCHAR(255)       DEFAULT 'Igor Sas',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted`         BOOLEAN            DEFAULT 0,
    UNIQUE KEY `link` (`link`),
    INDEX `run_id` (`run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
