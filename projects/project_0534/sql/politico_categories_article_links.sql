CREATE TABLE `politico_categories_article_links` (
    `id` BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `article_link` VARCHAR(255),
    `category_id` VARCHAR(255),
    `created_by` VARCHAR(255) DEFAULT 'Shahrukh Nawaz',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `data_source_url` VARCHAR(255),
    `run_id` BIGINT(20),
    `touched_run_id` BIGINT(20),
    `deleted` BOOLEAN DEFAULT 0,
    INDEX `run_id` (`run_id`),
    CONSTRAINT article_link_category_id UNIQUE (article_link, category_id)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'press_releases.politico_categories_article_links for Congress News from task 534. Made by Shahrukh Nawaz.';