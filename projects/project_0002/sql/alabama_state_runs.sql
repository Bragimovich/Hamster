CREATE TABLE `alabama_state_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `entity_id`       INT(11),
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Mariam Tahir',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `download_status` VARCHAR(255)       DEFAULT 'processing',
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `entity_id` (`entity_id`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
