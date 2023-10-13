CREATE TABLE `press_releases.us_dept_education_tags_article`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `article_link_id`              BIGINT(20),
    `us_dept_education_tag_id`	    BIGINT(20),
    constraint unique_records
        unique (article_link_id, us_dept_education_tag_id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
