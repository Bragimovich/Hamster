create table `us_dept_housing_and_urban_development`
(
  `id`                  int auto_increment   primary key,
  `title`               text,
  `teaser`              text,
  `article`             longtext,
  `link`                varchar(255),
  `creator`             varchar(100) default 'U.S. Dept of Housing & Urban Development',
  `type`                varchar(100) DEFAULT 'press release',
  `country`             varchar(100) DEFAULT 'US',
  `date`                DATETIME,
  `release_no`          varchar(255),
  `contact_info`        text,
  `scrape_frequency`    varchar(255)       DEFAULT 'Daily',
  `data_source_url`     VARCHAR(255),
  `created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
