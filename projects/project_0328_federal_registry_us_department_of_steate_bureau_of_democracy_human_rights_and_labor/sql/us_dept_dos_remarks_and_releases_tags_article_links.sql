create table `us_dept_dos_remarks_and_releases_tags_article_links`
(
  `id`                   int auto_increment   primary key,
  `tag_id`               bigint,
  `article_link`         varchar(512),
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`tag_id`,`article_link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
