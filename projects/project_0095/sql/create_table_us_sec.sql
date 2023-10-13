CREATE TABLE `us_sec`
(
  `id`               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`           BIGINT(20),
  `title`            varchar(255)                       null,
  `teaser`           text                               null,
  `article`          longtext                           null,
  `link`             varchar(255)                       null,
  `creator`          varchar(255)                       DEFAULT 'U.S. Securites and Exchange Commission',
  `type`             varchar(255)                       DEFAULT 'press release',
  `country`          varchar(255)                       DEFAULT 'US',
  `date`             DATETIME                           null,
  `release_no`       varchar(255)                       null,
  `dirty_news`       TINYINT(1)                         DEFAULT FALSE,
  `with_table`       TINYINT(1)                         DEFAULT FALSE,
  `scrape_frequency` varchar(255)                       DEFAULT 'daily',
  `data_source_url`  VARCHAR(255) DEFAULT 'https://www.sec.gov/news/pressreleases',
  `created_by`       VARCHAR(255)       DEFAULT 'Eldar M',
  `created_at`       DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;