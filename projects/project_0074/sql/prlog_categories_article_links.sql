use press_releases;
CREATE TABLE `prlog_categories_article_links`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `prlog_id`              BIGINT(20),
    `prlog_category_id`	    BIGINT(20),
    constraint unique_data
        unique (`prlog_id`, `prlog_category_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
