CREATE TABLE `us_cof_ranking_members_news`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `title`           varchar(1024),
  `subtitle`        varchar(1024),
  `teaser`          text,
  `article`         longtext,
  `link`            varchar(512),
  `creator`         varchar(100)       DEFAULT 'Ranking Member’s News',
  `type`            varchar(255)       DEFAULT 'press release',
  `country`         varchar(255)       DEFAULT 'US',
  `date`            DATE,
  `dirty_news`      tinyint(1)         DEFAULT 0,
  `with_table`      tinyint(1)         DEFAULT 0,
  `scrape_frequency`VARCHAR(50)        DEFAULT 'daily',
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
