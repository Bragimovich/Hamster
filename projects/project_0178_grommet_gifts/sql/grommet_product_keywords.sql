CREATE TABLE `grommet_product_keywords`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `keyword`      VARCHAR(255),
    `category_url`  VARCHAR(255),

  UNIQUE KEY `uniq_keyword` (keyword)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
