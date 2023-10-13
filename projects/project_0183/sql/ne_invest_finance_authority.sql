CREATE TABLE `ne_invest_finance_authority`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `title`           VARCHAR(255),
  `teaser`          TEXT,
  `article`         LONGTEXT,
  `link`            VARCHAR(255),
  `creator`         VARCHAR(255)       DEFAULT "Nebraska Investment Finance Authority",
  `type`            VARCHAR(255),
  `country`         VARCHAR(255)       DEFAULT 'US',
  `date`            DATETIME NULL,
  `contact_info`    VARCHAR(255),
  `dirty_news`      BOOLEAN            DEFAULT 0,  
  `with_table`      BOOLEAN            DEFAULT 0,
  `scrape_frequency` VARCHAR(255)      DEFAULT 'daily',
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Samuel Putz',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `link` (`link`),
  INDEX `run_id_idx` (`run_id`),
  INDEX `dirty_news_idx` (`dirty_news`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
