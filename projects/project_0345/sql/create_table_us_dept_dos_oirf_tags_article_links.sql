CREATE TABLE `us_dept_dos_oirf_tags_article_links`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `tag_id`          BIGINT(20),
    `article_link`    VARCHAR(400),
    `data_source_url` VARCHAR(255)       DEFAULT 'https://www.state.gov/remarks-and-releases-office-of-international-religious-freedom/',
    `created_by`      VARCHAR(255)       DEFAULT 'Igor Sas',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `article_tag_link` (`tag_id`, `article_link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
