create table `fdic`
(
  `id`                   int auto_increment   primary key,
  `title`                varchar(1024),
  `teaser`               text,
  `article`              longtext,
  `link`                 varchar(600),
  `creator`              varchar (255) default 'Federal Deposit Insurance Corporation',
  `type`                 varchar (255) default "press release",
  `country`              varchar (255) default "US",
  `date`                 date,
  `release_number`       varchar (255),
  `contact_info`         longtext,
  `data_source_url`      varchar (255),
  `dirty_news`           tinyint(1) default 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Tauseeq',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
