create table `us_eeoc`
(
`id`                  bigint auto_increment   primary key,
`title`               varchar(255),
`teaser`              text,
`article`             longtext,
`creator`             varchar(100)       DEFAULT 'Equal Employment Opportunity Commission',
`date`                DATE,
`link`                varchar(255),
`type`                varchar(100)       DEFAULT 'press release',
`country`             varchar(100)       DEFAULT 'US',
`data_source_url`     VARCHAR(255) ,
`scrape_frequency`    varchar(255)       DEFAULT 'Daily',
`created_by`          VARCHAR(255)       DEFAULT 'Adeel',
`created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
`updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
