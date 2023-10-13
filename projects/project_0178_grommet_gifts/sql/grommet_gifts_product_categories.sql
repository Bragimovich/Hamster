CREATE TABLE `grommet_gifts_product_categories`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `product_id`     BIGINT(20),
    `product_category_id`   BIGINT(20),

  UNIQUE KEY `unique_cat` (product_id, product_category_id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
