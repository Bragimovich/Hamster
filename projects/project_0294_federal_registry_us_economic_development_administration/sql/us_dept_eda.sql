create table `us_dept_eda`
(
`id`                  bigint auto_increment   primary key,
`title`               varchar(1024),
`subtitle`            varchar(1024),
`teaser`              text,
`article`             longtext,
`creator`             varchar(100)       DEFAULT 'Economic Development Administration',
`date`                DATE,
`link`                varchar(512),
`type`                varchar(100)       DEFAULT 'press release',
`country`             varchar(100)       DEFAULT 'US',
`dirty_news`          tinyint(1)         DEFAULT 0,
`with_table`          tinyint(1)         DEFAULT 0, 
`contact_info`        varchar(2048),
`data_source_url`     varchar(255),
`run_id`                 int,
`scrape_frequency`    varchar(255)       DEFAULT 'Daily',
`created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
`created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
`updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
