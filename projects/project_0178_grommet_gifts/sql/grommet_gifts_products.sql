CREATE TABLE `grommet_gifts_products`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `producer_name`                 VARCHAR(255),
  `product_name`                  VARCHAR(255),
  `product_short_description`     VARCHAR(255),
  `product_price_min`             VARCHAR(255),
  `product_price_max`             VARCHAR(255),
  `is_sold_out`                   VARCHAR(255),
  `rating`                        INT,
  `reviews_count`                 INT,
  `product_img_url`               VARCHAR(255),
  `product_url`                   VARCHAR(255),

  `data_source_url` VARCHAR(255)       DEFAULT 'https://www.thegrommet.com/gifts',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G.',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
