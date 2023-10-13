CREATE TABLE us_judical_conference_tags_article_links
(
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    article_link                VARCHAR(255) DEFAULT NULL,
    tag_id                      BIGINT(20) DEFAULT NULL,
    data_source_url             VARCHAR(255) DEFAULT 'https://www.consumerfinance.gov/about-us/newsroom',
    scrape_frequency            VARCHAR(255) DEFAULT 'daily',
    created_by                  VARCHAR(255) DEFAULT 'Andrey Tereshchenko',
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `article_category_link` (`article_link`,`tag_id`)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;