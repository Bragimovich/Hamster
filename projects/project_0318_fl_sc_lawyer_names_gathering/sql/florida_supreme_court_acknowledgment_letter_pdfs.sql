CREATE TABLE `florida_supreme_court_acknowledgment_letter_pdfs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_date_docketed`      date,
  `case_no`                 varchar(100),
  `pdf_date_docketed`       date,
  `pdf_link_on_aws`         varchar(255),
  `scrape_frequency`        VARCHAR(50)        DEFAULT 'daily',
  `data_source_url`         VARCHAR(255),
  `created_by`              VARCHAR(50)       DEFAULT 'Aqeel',
  `created_at`              DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`pdf_link_on_aws`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  