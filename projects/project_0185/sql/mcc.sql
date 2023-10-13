CREATE TABLE `mcc`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    # any columns
    `title`           VARCHAR(255)       DEFAULT NULL,
    `teaser`          VARCHAR(3000)      DEFAULT NULL,
    `article`         LONGTEXT           DEFAULT NULL,
    `creator`         VARCHAR(255)       DEFAULT 'Millenium Challenge Corporation',
    `country`         VARCHAR(2)         DEFAULT 'US',
    `date`            DATE               DEFAULT NULL,
    `link`            VARCHAR(255)       DEFAULT NULL,
    `contact_info`    VARCHAR(400)       DEFAULT NULL,
    `type`            VARCHAR(255)       DEFAULT NULL,
    `data_source_url` VARCHAR(255)       DEFAULT 'https://www.mcc.gov/news-and-events',
    `dirty_news`      TINYINT            DEFAULT 0,
    `with_table`      TINYINT            DEFAULT 0,
    # end any columns
    `created_by`      VARCHAR(255)       DEFAULT 'Eldar Eminov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
