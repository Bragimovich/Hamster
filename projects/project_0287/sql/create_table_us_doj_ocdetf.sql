CREATE TABLE `us_doj_ocdetf`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    `title`           VARCHAR(255),
    `subtitle`        VARCHAR(1000),
    `teaser`          TEXT,
    `article`         LONGTEXT,
    `city`            VARCHAR(255),
    `state`           VARCHAR(255),
    `contact_info`    TEXT,
    `date`            DATETIME,
    `link`            VARCHAR(400),
    `creator`         VARCHAR(255)       DEFAULT 'Organized Crime Drug Enforcement Task Forces',
    `type`            VARCHAR(255)       DEFAULT 'press releases',
    `country`         VARCHAR(255)       DEFAULT 'US',
    `data_source_url` VARCHAR(255)       DEFAULT 'https://www.justice.gov/ocdetf/press-room',
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
