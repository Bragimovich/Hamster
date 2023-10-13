create table `us_dept_faa`
(
`id`                  bigint auto_increment   primary key,
`title`               varchar(1024),
`teaser`              text,
`article`             longtext,
`creator`             varchar(100)       DEFAULT 'Federal Aviation Administration',
`date`                DATE,
`link`                varchar(512),
`type`                varchar(100)       DEFAULT 'press release',
`country`             varchar(100)       DEFAULT 'US',
`dirty_news`          tinyint(1)         DEFAULT 0,
`with_table`          tinyint(1)         DEFAULT 0, 
`data_source_url`     varchar(255),
`scrape_frequency`    varchar(255)       DEFAULT 'Daily',
`created_by`          VARCHAR(255)       DEFAULT 'Adeel',
`created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
`updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  