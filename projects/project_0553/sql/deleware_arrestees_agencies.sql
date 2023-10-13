CREATE TABLE `deleware_arrestees_agencies`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestees_id`    BIGINT(20),
  `agencies_id`     BIGINT(20),
  `created_by`      VARCHAR(255)      DEFAULT 'Abdul Wahab',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
