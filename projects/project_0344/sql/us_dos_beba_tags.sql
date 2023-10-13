CREATE TABLE `us_dos_beba_tags`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `tag`             VARCHAR(100)        DEFAULT NULL,
    `created_by`      VARCHAR(30)        DEFAULT 'Eldar Eminov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `tag` (`tag`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;