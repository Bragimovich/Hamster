create table `peace_corps`
(
  `id`                  bigint auto_increment   primary key,
  `title`               varchar(255)       ,
  `teaser`              text               ,
  `article`             text               ,
  `link`                varchar(255)       ,
  `creator`             varchar(100)       DEFAULT 'Peace Corps',
  `type`                varchar(100)       ,
  `country`             varchar(100)       DEFAULT 'US',
  `date`                DATETIME           ,
  `contact_info`        VARCHAR(255)       ,
  `data_source_url`     VARCHAR(255)       ,
  `scrape_frequency`    varchar(255)       DEFAULT 'Daily',
  `created_by`          VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`         DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;