CREATE TABLE `usda_fsa`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `title`           VARCHAR(220)       DEFAULT NULL,
    `teaser`          VARCHAR(650)       DEFAULT NULL,
    `article`         MEDIUMTEXT         DEFAULT NULL,
    `link`            VARCHAR(255)       DEFAULT NULL,
    `creator`         VARCHAR(60)        DEFAULT 'U.S. Department of Agriculture Farm Service Agency',
    `type`            VARCHAR(30)        DEFAULT 'press release',
    `country`         VARCHAR(2)         DEFAULT 'US',
    `contact_info`    VARCHAR(1000)      DEFAULT NULL,
    `date`            DATETIME           DEFAULT NULL,
    `dirty_news`      TINYINT(1)         DEFAULT 0,
    `with_table`      TINYINT(1)         DEFAULT 0,
    `data_source_url` VARCHAR(255)       DEFAULT 'https://www.fsa.usda.gov/news-room/news-releases/index',
    `created_by`      VARCHAR(30)        DEFAULT 'Eldar Eminov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
