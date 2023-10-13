CREATE TABLE `us_dept_cisa_categories_article_links`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `article_link`      VARCHAR(511),
    `category_id`          BIGINT(20),
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `link_tag` (`article_link`, `category_id`),
    INDEX `category_id` (`category_id`),
    INDEX `article_link` (`article_link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
