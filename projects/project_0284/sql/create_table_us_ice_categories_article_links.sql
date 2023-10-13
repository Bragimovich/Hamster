CREATE TABLE `us_ice_categories_article_links`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `category_id`     BIGINT(20),
    `article_link`    VARCHAR(400),
    `data_source_url` VARCHAR(255)       DEFAULT 'https://www.ice.gov/newsroom',
    `created_by`      VARCHAR(255)       DEFAULT 'Igor Sas',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `article_category_link` (`category_id`, `article_link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
