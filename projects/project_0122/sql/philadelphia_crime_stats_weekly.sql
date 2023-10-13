CREATE TABLE `philadelphia_crime_stats_weekly`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `report_id`       BIGINT(20),   
  `week_number`     INT,
  `crime_section`         VARCHAR(155),
  `crime_type`         VARCHAR(255),
  `number_of_incidents`     INT,
  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`report_id` , `week_number` , `crime_section` , `crime_type` , `number_of_incidents`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
