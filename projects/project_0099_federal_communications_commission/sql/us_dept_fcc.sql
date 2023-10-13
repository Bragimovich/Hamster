create table `us_dept_fcc`
(
  `id`                  bigint auto_increment   primary key,
  `title`               varchar(255)       ,
  `teaser`              text               ,
  `article`             text           ,
  `link`                varchar(255)       ,
  `creator`             varchar(100)       DEFAULT 'Federal Communications Commission',
  `type`                varchar(100)       DEFAULT 'news release',
  `country`             varchar(100)       DEFAULT 'US',
  `date`                DATETIME           ,
  `contact_info`        text               ,
  `file_link`           varchar(255)      , 
  `file_name`           varchar(255)      ,
  `scrape_frequency`    varchar(255)       DEFAULT 'Daily',
  `data_source_url`     VARCHAR(255)      ,
  `created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 UNIQUE KEY `unique_data` (`link` , `file_link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
