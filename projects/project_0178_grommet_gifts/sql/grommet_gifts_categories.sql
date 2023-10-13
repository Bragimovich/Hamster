CREATE TABLE `grommet_gifts_categories`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `category`      VARCHAR(255),
    `sub_category`  VARCHAR(255),
    `category_url`  VARCHAR(255),

  UNIQUE KEY `unique_cat` (category, sub_category)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
