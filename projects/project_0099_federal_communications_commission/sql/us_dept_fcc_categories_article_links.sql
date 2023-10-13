create table `us_dept_fcc_categories_article_links`
(
  `id`                  BIGINT auto_increment   primary key,
  `article_link`        VARCHAR(255)       , 
  `category_id`         bigint,
  `data_source_url`     VARCHAR(255),
  `created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
  `scrape_frequency`    VARCHAR(255)       DEFAULT 'Daily', 
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
UNIQUE KEY `unique_data` (`article_link` , `category_id`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
