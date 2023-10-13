CREATE TABLE `us_dhs_fema_tags_article_links`
(
    `id`           BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `tag_id`       VARCHAR(50)        DEFAULT NULL,
    `article_link` VARCHAR(255)       DEFAULT NULL,
    `created_by`   VARCHAR(30)        DEFAULT 'Eldar Eminov',
    `created_at`   DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `article_link_tag_id` (`article_link`, `tag_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
