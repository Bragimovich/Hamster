create table `us_dept_nps`
(
  `id`                   int auto_increment   primary key,
  `run_id`               BIGINT(20),
  `title`                varchar(2024),
  `teaser`               text,
  `article`              longtext,
  `link`                 varchar(500),
  `creator`              varchar (255) default 'Committee on Education & Labor Republicans',
  `type`                 varchar (255) default "press release",
  `country`              varchar (255) default "US",
  `city`                 varchar (255),
  `state`                varchar (255),
  `date`                 date,
  `dirty_news`           tinyint(1) default 0,
  `with_table`           tinyint(1) default 0,
  `contact_info`         text,
  `data_source_url`      varchar (255) default "https://www.nps.gov/aboutus/news/news-releases.htm#sort=Date_Released+desc&fq%5B%5D=Date_Released%3A%5B2002-01-07T00%3A00%3A00Z+TO+2022-01-07T00%3A00%3A00Z%5D",
  `scrape_frequency`     VARCHAR(255)       DEFAULT 'Daily',
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
