create table `ftc`
(
`id`                  bigint auto_increment   primary key,
`title`               varchar(255),
`teaser`              text,
`article`             longtext,
`creator`             varchar(100)       DEFAULT 'Federal Trade Commission',
`type`                varchar(100)       DEFAULT 'press release',
`country`             varchar(100)       DEFAULT 'US',
`contact_info`        text,
`link`                varchar(255),
`date`                DATETIME,
`data_source_url`     VARCHAR(255)       DEFAULT 'https://www.ftc.gov/news-events', 
`scrape_frequency`    varchar(255)       DEFAULT 'Daily',
`created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
`created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
`updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
