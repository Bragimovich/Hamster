CREATE TABLE `philadelphia_crime_stats_reports`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `year`            VARCHAR(255),
  `week_number`     INT,
  `start_date`      DATETIME,
  `end_date`        DATETIME,
  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`year` , `week_number` , `start_date` , `end_date`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
