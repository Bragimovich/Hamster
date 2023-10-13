CREATE TABLE `texas_run`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `download_status` VARCHAR(255)       DEFAULT 'processing',
  INDEX `status_idx` (`status`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
