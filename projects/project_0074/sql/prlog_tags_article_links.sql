use press_releases;
CREATE TABLE `prlog_tags_article_links`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `prlog_id`              BIGINT(20),
    `prlog_tag_id`	    BIGINT(20),
    constraint unique_records
        unique (prlog_id, prlog_tag_id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
