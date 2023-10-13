CREATE TABLE `ntsb`
(
  `id`              BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
  `title`			      VARCHAR(255),
  `teaser`			    TEXT,
  `article`			    LONGTEXT,
  `creator`			    VARCHAR(255)  DEFAULT 'National Transportation Safety Board',
  `date`			      DATETIME,
  `link`			      VARCHAR(255),
  `type`			      VARCHAR(255)  DEFAULT 'press release',
  `data_source_url` VARCHAR(255)  DEFAULT 'https://www.ntsb.gov/news/press-releases/Pages/ByYear.aspx',
  `country`			    VARCHAR(255)  DEFAULT 'US',
  `created_by`      VARCHAR(255)  DEFAULT 'Oleksii Kuts',
  `created_at`      DATETIME      DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
