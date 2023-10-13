CREATE TABLE `us_dept_celr_tags_article_links`
(
`id`                  bigint auto_increment   primary key,
`article_link`        varchar(512),
`tag_id`              bigint,    
`created_by`          VARCHAR(255)       DEFAULT 'Aqeel',
`created_at`          DATETIME           ,
`updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
UNIQUE KEY `unique_data` (`article_link`, `tag_id`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
