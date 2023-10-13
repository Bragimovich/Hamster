CREATE TABLE `hawaii_fire_department_chief_monthly_report`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `document_name`           varchar(255),
  `folder_name`             varchar(100),
  `folder_url`              varchar(100),
  `page_count`              int,
  `src_date_created`        date, 
  `src_date_modified`       date,
  `src_pdf_link`            varchar(255),
  `aws_pdf_link`            varchar(255),
  `scrape_frequency`        VARCHAR(50)        DEFAULT 'monthly',
  `data_source_url`         VARCHAR(255),
  `md5_hash`                varchar (255),
  `run_id`                  int,
  `deleted`                 int DEFAULT 0,
  `created_by`              VARCHAR(50)       DEFAULT 'Adeel',
  `created_at`              DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
