CREATE TABLE us_judical_conference_tags
(
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    tag                         VARCHAR(255) DEFAULT NULL,
    data_source_url             VARCHAR(255) DEFAULT 'https://www.uscourts.gov/judiciary-news',
    scrape_frequency            VARCHAR(255) DEFAULT 'daily',
    created_by                  VARCHAR(255) DEFAULT 'Andrey Tereshchenko',
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `category` (`tag`)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;