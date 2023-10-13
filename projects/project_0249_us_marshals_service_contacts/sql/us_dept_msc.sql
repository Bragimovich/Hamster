CREATE TABLE `us_dept_msc`
(
`id`                  bigint auto_increment   primary key,
`run_id`              int,
`title`               varchar(1024),
`teaser`              text,
`article`             longtext,
`creator`             varchar(100)       DEFAULT 'U.S. Marshals Service Contacts',
`date`                DATE,
`link`                varchar(512),
`type`                varchar(100)       DEFAULT 'news release',
`country`             varchar(100)       DEFAULT 'US',
`dirty_news`          tinyint(1)         DEFAULT 0,
`with_table`          tinyint(1)         DEFAULT 0,
`contact_info`        text,
`data_source_url`     varchar(255),
`scrape_frequency`    varchar(255)       DEFAULT 'Daily',
`created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
`created_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
