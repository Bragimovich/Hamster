CREATE TABLE `delaware_state_covid_data_run`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `date`            date,
  `created_by`      VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`date` , `status`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
