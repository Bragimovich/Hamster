CREATE TABLE `ptd_embassy`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `title`			  VARCHAR(255),
    `teaser`		  VARCHAR(1000),
    `article`		  LONGTEXT,
    `creator`		  VARCHAR(255)  DEFAULT 'Embassy of Portugal to the United States of America',
    `date`			  DATETIME,
    `link`			  VARCHAR(500),
    `type`			  VARCHAR(255)  DEFAULT 'press release',
    `country`		  VARCHAR(255)  DEFAULT 'Portugal',
    `data_source_url` VARCHAR(255)  DEFAULT 'https://washingtondc.embaixadaportugal.mne.gov.pt/en/the-embassy/news',
    `dirty_news`      tinyint(1) DEFAULT 0,
    `with_table`      tinyint(1) DEFAULT 0,
    `created_by`      VARCHAR(255)       DEFAULT 'Pospelov Vyacheslav',
    `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;