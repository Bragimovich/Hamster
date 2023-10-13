CREATE TABLE `loc`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `title`               varchar(255)      ,
  `subtitle`            varchar(255)      ,
  `teaser`              text               ,
  `article`             longtext               ,
  `link`               varchar(255)       ,
  `creator`             varchar(100)       DEFAULT 'Library of Congress',
  `type`                varchar(100)       DEFAULT 'press release',
  `country`             varchar(100)       DEFAULT 'US',
  `date`                DATETIME           ,
  `release_no`         varchar(255),
  `issn`                varchar(255),
  `contact_info`        longtext,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  