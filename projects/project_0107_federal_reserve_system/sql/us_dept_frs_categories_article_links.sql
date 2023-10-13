CREATE TABLE `us_dept_frs_categories_article_links`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `article_link` VARCHAR(255),
  `prlog_category_id` BIGINT(20),
  `created_by`      VARCHAR(255)       DEFAULT 'Eldar M.',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `article_link_prlog_category_id` (`article_link`, `prlog_category_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

ALTER TABLE us_dept_frs_categories_article_links ALTER COLUMN created_by SET DEFAULT 'Oleksii Kuts';
ALTER TABLE us_dept_frs_categories_article_links COMMENT 'Article <--> Category reference from federalreserve.gov, Created by Eldar M., Updated by Oleksii Kuts, Task #107';
