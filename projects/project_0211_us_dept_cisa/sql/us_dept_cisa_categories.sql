CREATE TABLE `us_dept_cisa_categories`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `category`             VARCHAR(255),
  `category_link`        VARCHAR(255),

  UNIQUE KEY `category_unique` (`category`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
