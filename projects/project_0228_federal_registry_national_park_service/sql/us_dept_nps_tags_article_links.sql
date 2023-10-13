create table `us_dept_nps_tags_article_links`
(
  `id`                   int auto_increment   primary key,
  `run_id`               BIGINT(20),
  `prlog_tag_id`         bigint,
  `article_link`         varchar(255),
  `scrape_frequency`     VARCHAR(255)       DEFAULT 'Daily',
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`prlog_tag_id`,`article_link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
