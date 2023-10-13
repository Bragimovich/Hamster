CREATE TABLE IF NOT EXISTS `us_dept_hssat_category_article_links`(
   `id` bigint(20) NOT NULL AUTO_INCREMENT  primary key,
   `category_id` varchar(255),
   `article_link` varchar(512),
   UNIQUE KEY `unique_data` (`article_link`,`category_id`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
