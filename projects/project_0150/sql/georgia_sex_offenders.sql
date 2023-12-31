CREATE TABLE Georgia
(
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name                        VARCHAR(255) NOT NULL,
    sex                         VARCHAR(255) NOT NULL,
    race                        VARCHAR(255) DEFAULT NULL,
    year_of_birth               INT DEFAULT NULL,
    height                      INT DEFAULT NULL,
    weight                      INT DEFAULT NULL,
    hair_color                  VARCHAR(255) DEFAULT NULL,
    eye_color                   VARCHAR(255) DEFAULT NULL,
    street_number               VARCHAR(255) DEFAULT NULL,
    street                      VARCHAR(255) DEFAULT NULL,
    city                        VARCHAR(255) DEFAULT NULL,
    state                       VARCHAR(255) DEFAULT NULL,
    zip_code                    VARCHAR(255) DEFAULT NULL,
    county                      VARCHAR(255) DEFAULT NULL,
    registration_date           DATE DEFAULT NULL,
    crime                       VARCHAR(400) DEFAULT NULL,
    conviction_date             DATE DEFAULT NULL,
    conviction_state            VARCHAR(255) DEFAULT NULL,
    incarcerated                VARCHAR(255) DEFAULT NULL,
    predator                    VARCHAR(255) DEFAULT NULL,
    absconder                   VARCHAR(255) DEFAULT NULL,
    res_verification_date       DATE DEFAULT NULL,
    leveling                    VARCHAR(255) DEFAULT NULL,
    data_source_url             VARCHAR(255) DEFAULT 'https://gbi.georgia.gov/services/georgia-sex-offender-registry',
    scrape_frequency            VARCHAR(255) DEFAULT 'weekly',
    created_by                  VARCHAR(255) DEFAULT 'Andrey Tereshchenko',
    last_scrape_date            DATE DEFAULT NULL,
    next_scrape_date            DATE DEFAULT NULL,
    run_id                      INT,
    touched_run_id              INT,
    deleted                     BOOLEAN DEFAULT 0,
    md5_hash                    VARCHAR(255) DEFAULT NULL,
    md5_uniq                    VARCHAR(255) DEFAULT NULL,
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX run_id (run_id),
    INDEX touched_run_id (touched_run_id),
    INDEX md5_hash (md5_hash)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
