create table `us_dept_agricultural_archive`
(
  `id`                   int auto_increment   primary key,
  `title`                varchar(1024),
  `teaser`               text,
  `article`              longtext,
  `link`                 varchar(500),
  `creator`              varchar (255) default 'DEPARTMENT OF AGRICULTURE',
  `type`                 varchar (255) default "press release",
  `country`              varchar (255) default "US",
  `date`                 date,
  `contact_info`        varchar (255),
  `dirty_news`           tinyint(1) default 0,
  `with_table`           tinyint(1) default 0,
  `data_source_url`      varchar (255),
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
