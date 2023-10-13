CREATE TABLE `grommet_product_to_keyword`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `product_id`     BIGINT(20),
    `keyword_id`   BIGINT(20),

  UNIQUE KEY `unique_key` (product_id, keyword_id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
