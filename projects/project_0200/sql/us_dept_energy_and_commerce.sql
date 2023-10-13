CREATE TABLE us_dept_energy_and_commerce
(
    id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(255),
    teaser          TEXT,
    article         LONGTEXT,
    link            VARCHAR(255),
    creator         VARCHAR(255)        DEFAULT 'The Committee on Energy and Commerce',
    type            VARCHAR(255)        DEFAULT 'press release',
    country         VARCHAR(255)        DEFAULT 'US',
    date            DATETIME,
    dirty_news      TINYINT(1)          DEFAULT FALSE,
    with_table      TINYINT(1)          DEFAULT FALSE,
    created_by      VARCHAR(255)        DEFAULT 'Abdur Rehman',
    created_at      DATETIME            DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    data_source_url  VARCHAR(255) DEFAULT 'https://energycommerce.house.gov',
    run_id  BIGINT,
    touched_run_id BIGINT(20),
    deleted BOOLEAN  default 0,
    md5_hash  VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  KEY id (id)
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;