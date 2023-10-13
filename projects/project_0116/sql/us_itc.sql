create table `us_itc`
(
`id`                  bigint auto_increment   primary key,
`title`               varchar(255),
`teaser`              text,
`article`             longtext,
`link`                varchar(255),
`creator`             varchar(100)       DEFAULT 'US International Trade Comission',
`type`                varchar(100)       DEFAULT 'press release',
`country`             varchar(100)       DEFAULT 'US',
`release_no`          varchar(255),
`date`                DATETIME,
`contact_info`        text ,
`data_source_url`     VARCHAR(255) ,
`scrape_frequency`    varchar(255)       DEFAULT 'Daily',
`created_by`          VARCHAR(255)       DEFAULT 'Adeel',
`created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
`updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
