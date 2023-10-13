CREATE TABLE us_dept_energy_and_commerce_categories_article_links
(
    id                  INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    article_link        VARCHAR(255),
    category_id         BIGINT,
    created_by          VARCHAR(255)    DEFAULT 'Abdur Rehman',
    created_at          DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY article_link_category_id (article_link, category_id)
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;