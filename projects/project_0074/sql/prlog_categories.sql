CREATE TABLE `prlog_categories`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `category`				VARCHAR(255),
    UNIQUE KEY `category` (`category`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
