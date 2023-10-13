create table `us_dept_cftc_categories_article_links`
(
  `id`                  BIGINT auto_increment   primary key,
  `article_link`        VARCHAR(255)      , 
  `prlog_category_id`   bigint,
  `data_source_url`     VARCHAR(255),
  `created_by`          VARCHAR(255)       DEFAULT 'Adeel',
  `scrape_frequency`    VARCHAR(255)       DEFAULT 'Daily', 
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`prlog_category_id` , `article_link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;