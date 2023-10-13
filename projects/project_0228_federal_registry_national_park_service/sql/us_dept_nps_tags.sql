create table `us_dept_nps_tags`
(
  `id`                   int auto_increment   primary key,
  `run_id`               BIGINT(20),
  `tag`                  varchar(255),
  `scrape_frequency`     VARCHAR(255)       DEFAULT 'Daily',
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`tag`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
