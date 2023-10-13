CREATE TABLE `us_dept_eda_tags`(
  `id` bigint(20) NOT NULL AUTO_INCREMENT  primary key,
  `tag` varchar(255),
  `tag_link` varchar(255),
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`tag`,`tag_link`)
  )DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
