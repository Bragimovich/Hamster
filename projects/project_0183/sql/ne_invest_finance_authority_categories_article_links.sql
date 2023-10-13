CREATE TABLE `ne_invest_finance_authority_categories_article_links`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `article_link`    VARCHAR(255),
  `prlog_category_id` BIGINT(20),
  `created_by`      VARCHAR(255)       DEFAULT 'Samuel Putz',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `article_link_prlog_category_id` (`article_link`, `prlog_category_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;