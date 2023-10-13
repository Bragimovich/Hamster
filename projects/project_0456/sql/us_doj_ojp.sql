create table `us_doj_ojp`
(
  `id`                   int auto_increment   primary key,
  `run_id`               int default NULL,
  `title`                varchar(1024),
  `subtitle`             varchar(1024) default NULL,
  `teaser`               text,
  `article`              longtext,
  `link`                 varchar(600),
  `creator`              varchar (255) default 'U.S. Department of Justice, Office of Justice Programs',
  `type`                 varchar (255) default "press release",
  `country`              varchar (255) default "US",
  `date`                 date,
  `release_number`       varchar (255) default NULL,
  `contact_info`         longtext,
  `data_source_url`      varchar (255),
  `dirty_news`           tinyint(1) default 0,
  `with_table`           tinyint(1) default 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Tauseeq',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
