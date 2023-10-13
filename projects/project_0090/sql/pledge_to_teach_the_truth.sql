CREATE TABLE pledge_to_teach_the_truth
(
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name                        VARCHAR(255),
    city                        VARCHAR(255),
    state                       VARCHAR(255),
    comment                     VARCHAR(8000),
    datasource_url              VARCHAR(255) DEFAULT 'https://www.zinnedproject.org/news/pledge-to-teach-truth',
    scrape_frequency            VARCHAR(255) DEFAULT 'daily',
    created_by                  VARCHAR(255) DEFAULT 'Andrey Tereshchenko',
    last_scrape_date            DATE DEFAULT NULL,
    next_scrape_date            DATE DEFAULT NULL,
    dataset_name_prefix         VARCHAR(255) DEFAULT 'pledge to teach the truth',
    scrape_status               VARCHAR(255) DEFAULT 'live',
    pl_gather_task_id           VARCHAR(255) DEFAULT NULL,
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                      INT,
    touched_run_id              INT,
    deleted                     BOOLEAN DEFAULT 0,
    md5_hash                    VARCHAR(255),
    INDEX run_id (run_id),
    INDEX touched_run_id (touched_run_id)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
