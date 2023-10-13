us_postal_service.sql
CREATE TABLE us_postal_service
(
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    title                       VARCHAR(255) DEFAULT NULL,
    teaser                      VARCHAR(1000) DEFAULT NULL,
    article                     LONGTEXT DEFAULT NULL,
    link                        VARCHAR(300) DEFAULT NULL,
    type                        VARCHAR(255) DEFAULT 'press release',
    creator                     VARCHAR(255) DEFAULT 'U.S. Postal Service',
    country                     VARCHAR(255) DEFAULT 'US',
    date                        DATETIME DEFAULT NULL,
    dirty_news                  TINYINT DEFAULT 0,
    data_source_url             VARCHAR(255) DEFAULT 'https://about.usps.com/newsroom/national-releases/',
    scrape_frequency            VARCHAR(255) DEFAULT 'daily',
    created_by                  VARCHAR(255) DEFAULT 'Andrey Tereshchenko',
    dataset_name_prefix         VARCHAR(255) DEFAULT 'Federal Register',
    scrape_status               VARCHAR(255) DEFAULT 'live',
    pl_gather_task_id           VARCHAR(255) DEFAULT NULL,
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `link` (`link`)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;