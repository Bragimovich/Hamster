CREATE TABLE `us_dept_eda_tags_article_links`(
  `id` bigint(20) NOT NULL AUTO_INCREMENT  primary key,
  `tag_id` varchar(255),
  `article_link` varchar(512),
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`article_link`,`tag_id`)
  )DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
