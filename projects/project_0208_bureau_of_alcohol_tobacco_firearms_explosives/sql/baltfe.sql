CREATE TABLE `baltfe`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  # any columns
  `title`           varchar(1024),
  `subtitle`        varchar(1024),
  `teaser`          TEXT,
  `article`         longtext,
  `link`            varchar(255),
  `creator`         varchar(100)       DEFAULT 'Bureau of Alcohol, Tobacco, Firearms and Explosives',
  `type`            varchar(255)       DEFAULT 'press release',
  `contact_info`    TEXT,
  `country`         varchar(255)       DEFAULT 'US',
  `date`            DATE,
  `dirty_news`      tinyint(1)         DEFAULT 0,
  `with_table`      tinyint(1)         DEFAULT 0,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Aqeel',
  `scrape_frequency` VARCHAR(50)        DEFAULT 'daily',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
