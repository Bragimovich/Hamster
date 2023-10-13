CREATE TABLE us_dept_bureau_of_political_military_affairs_tags_article_links
(
    id           INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    article_link VARCHAR(255),
    tag_id       BIGINT,
    created_by   VARCHAR(255) DEFAULT 'Eldar Mustafaiev',
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY article_link_tag_id (article_link, tag_id)
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;