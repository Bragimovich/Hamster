create table `va_office_reports`
(
  `id`                   int auto_increment   primary key,
  `title`                VARCHAR(255),
  `has_location`         tinyint(1) default 0,
  `link_to_report`       VARCHAR(255),
  `date`                 date,
  `report_number`        VARCHAR(255),
  `va_office`            VARCHAR(255),
  `report_author`        VARCHAR(255),
  `report_type`          VARCHAR(255),
  `release_type`         VARCHAR(255),
  `summary`              longtext,
  `data_source_url`      VARCHAR(255),
  `scrape_frequency`     varchar(255)       DEFAULT 'Daily',
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link_to_report`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
