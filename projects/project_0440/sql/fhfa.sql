CREATE TABLE `fhfa`
(
    `id`              BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
    `title`			  VARCHAR(255),
    `teaser`	      VARCHAR(255),
    `article`		  LONGTEXT,
    `link`			  VARCHAR(255),
    `creator`		  VARCHAR(255)  DEFAULT 'Federal Housing Finance Agency',
    `type`			  VARCHAR(255)  DEFAULT 'press release',
    `country`		  VARCHAR(255)  DEFAULT 'US',
    `date`			  DATETIME,
    `contact_info`    TEXT,
    `data_source_url` VARCHAR(255)  DEFAULT 'https://www.fhfa.gov/Media',
    `dirty_news`      tinyint(1) DEFAULT 0,
    `with_table`      tinyint(1) DEFAULT 0,
    `created_by`      VARCHAR(255)       DEFAULT 'Pospelov Vyacheslav',
    `created_at`      DATETIME      DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
