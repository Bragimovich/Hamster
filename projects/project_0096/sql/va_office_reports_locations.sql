create table `va_office_reports_locations`
(
  `id`                   int auto_increment   primary key,
  `va_office_reports_id` bigint,
  `city`                 VARCHAR(255),
  `state`                VARCHAR(255),
  `data_source_url`      VARCHAR(255),
  `scrape_frequency`      varchar(255)       DEFAULT 'Daily',
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`va_office_reports_id`,`city`,`state`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
