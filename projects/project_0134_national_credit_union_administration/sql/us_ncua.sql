create table `us_ncua`
(
  `id`                  int auto_increment   primary key,
  `us_ncua_categorie_id`   int,
  `title`               text,
  `subtitle`            text,
  `teaser`              text,
  `article`             longtext,
  `link`                varchar(255),
  `creator`             varchar(100) default 'National Credit Union Administration',
  `type`                varchar(100) DEFAULT 'press release',
  `country`             varchar(100) DEFAULT 'US',
  `date`                date,
  `contact_info`        text,
  `scrape_frequency`    varchar(255)       DEFAULT 'Daily',
  `data_source_url`     VARCHAR(255),
  `created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
