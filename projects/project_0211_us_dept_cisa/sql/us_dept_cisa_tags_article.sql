CREATE TABLE `us_dept_cisa_tags_article_link`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `article_link`      VARCHAR(511),
    `tag_id`          BIGINT(20),
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `link_tag` (`article_link`, `tag_id`),
    INDEX `tag_id` (`tag_id`),
    INDEX `article_link` (`article_link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
