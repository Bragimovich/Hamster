CREATE TABLE `us_doj_fbi_bureau_office_article`
(
  `id`             int AUTO_INCREMENT PRIMARY KEY,
  `article_link`   VARCHAR(500),
  `bureau_office`  VARCHAR(255),
  `created_by`     VARCHAR(255)       DEFAULT 'Abdur Rehman',
  `created_at`     DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`bureau_office`,`article_link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

-- drop table us_doj_fbi_bureau_office_article