use press_releases;
CREATE TABLE `prlog_tags`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `tag`				VARCHAR(255),
    UNIQUE KEY `tag` (`tag`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

