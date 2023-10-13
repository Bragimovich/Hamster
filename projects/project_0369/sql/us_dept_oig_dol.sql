create table `us_dept_oig_dol`
(
  `id`                   int auto_increment   primary key,
  `title`                varchar(1024),
  `teaser`               text,
  `article`              longtext,
  `link`                 varchar (600),
  `subtitle`             varchar (1000),
  `state`                varchar (255),
  `contact_info`         varchar (1000),
  `creator`              varchar (255) default 'UNITED STATES DEPARTMENT OF LABOR',
  `type`                 varchar (255) default "press release",
  `country`              varchar (255) default "US",
  `date`                 date,
  `run_id`               int
  `dirty_news`           tinyint(1) default 0,
  `with_table`           tinyint(1) default 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `scrape_frequency`     VARCHAR(255)       DEFAULT 'Daily',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
