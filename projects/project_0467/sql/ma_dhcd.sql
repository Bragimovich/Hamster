create table `ma_dhcd`
(
  `id`                        int auto_increment   primary key,
  `run_id`                    int,
  `title`                     varchar (500),
  `teaser`                    varchar (1000),
  `article`                   longtext,
  `date`                      date,
  `link`                      varchar (255),
  `creator`                   varchar (255) DEFAULT 'Maryland Department of Housing and Community Development',
  `data_source_url`           varchar (255) DEFAULT 'http://www.dhcd.maryland.gov/',
  `type`                      varchar (255) DEFAULT 'Press Release',
  `country`                   varchar (255) DEFAULT 'US',
  `dirty_news`                int DEFAULT 0,
  `with_table`                int DEFAULT 0,
  `created_by`                varchar (255)   DEFAULT 'Tauseeq',    
  `created_at`                DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
  )DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
