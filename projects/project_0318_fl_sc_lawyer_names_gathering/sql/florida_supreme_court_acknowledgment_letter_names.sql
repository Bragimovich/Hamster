CREATE TABLE `florida_supreme_court_acknowledgment_letter_names`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `lawyer_id`               BIGINT(20),
  `lawyer_name`             varchar(255),
  `scrape_frequency`        VARCHAR(50)        DEFAULT 'daily',
  `data_source_url`         VARCHAR(255),
  `created_by`              VARCHAR(50)       DEFAULT 'Aqeel',
  `created_at`              DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`lawyer_id` , `lawyer_name` , `data_source_url`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  