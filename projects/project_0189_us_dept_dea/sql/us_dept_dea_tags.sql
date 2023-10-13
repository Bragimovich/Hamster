CREATE TABLE `us_dept_dea_tags`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `tag`             VARCHAR(255),

  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `tag_unique` (`tag`),
  INDEX `tag` (`tag`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
