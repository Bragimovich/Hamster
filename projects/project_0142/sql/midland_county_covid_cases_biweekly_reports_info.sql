CREATE TABLE midland_county_covid_cases_biweekly_reports_info
(
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    report_id                   BIGINT NOT NULL,
    concept                     VARCHAR(255) DEFAULT NULL,
    label                       VARCHAR(255) DEFAULT NULL,
    cases                       BIGINT DEFAULT NULL,
    pct_of_total                DECIMAL(10,2) DEFAULT NULL,
    data_source_url             VARCHAR(255) DEFAULT 'https://www.midlandtexas.gov/978/Midland-County-COVID-19-Report',
    scrape_frequency            VARCHAR(255) DEFAULT 'biweekly',
    created_by                  VARCHAR(255) DEFAULT 'Andrey Tereshchenko',
    last_scrape_date            DATE DEFAULT NULL,
    next_scrape_date            DATE DEFAULT NULL,
    run_id                      INT,
    touched_run_id              INT,
    deleted                     BOOLEAN DEFAULT 0,
    md5_hash                    VARCHAR(255) DEFAULT NULL,
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX run_id (run_id),
    INDEX touched_run_id (touched_run_id),
    INDEX md5_hash (md5_hash),
    CONSTRAINT `fk_covid_cases` FOREIGN KEY (`report_id`) REFERENCES `midland_county_covid_cases_biweekly_reports` (`id`) on delete cascade
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
