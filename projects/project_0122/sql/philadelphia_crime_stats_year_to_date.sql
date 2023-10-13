CREATE TABLE `philadelphia_crime_stats_year_to_date`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `report_id`       BIGINT(20),   
  `year`            VARCHAR(100),
  `to_date`          DATETIME,
  `crime_section`         VARCHAR(155),
  `crime_type`         VARCHAR(255),
  `number_of_incidents`     INT,
  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`report_id` , `year` , `to_date` , `crime_section` , `crime_type` , `number_of_incidents`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
