create table `us_dept_scanf_majority`
(
  `id`                   int auto_increment   primary key,
  `title`                varchar(2024),
  `subtitle`             varchar(3024),
  `teaser`               varchar(6024),
  `article`              longtext,
  `link`                 varchar(500),
  `creator`              varchar (255) default "US Senate Committee On Agriculture, Nutrition, &  Forestry",
  `type`                 varchar (255) default "press release",
  `country`              varchar (255) default "US",
  `date`                 date,
  `dirty_news`           tinyint(1) default 0,
  `with_table`           tinyint(1) default 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
