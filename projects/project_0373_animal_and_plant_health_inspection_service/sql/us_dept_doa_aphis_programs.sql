create table `us_dept_doa_aphis_programs`
(
  `id`                   int auto_increment   primary key,
  `title`                varchar(1024),
  `teaser`               text,
  `article`              longtext,
  `link`                 varchar(600),
  `creator`              varchar (255) default 'Animal and Plant Health Inspection Service',
  `type`                 varchar (255) default "press release",
  `country`              varchar (255) default "US",
  `contact_info`         longtext,
  `date`                 date,
  `dirty_news`           tinyint(1) default 0,
  `with_table`           tinyint(1) default 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
