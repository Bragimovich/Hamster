CREATE TABLE us_dept_ways_and_means
(
    id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(255),
    subtitle        VARCHAR(255),
    teaser          TEXT,
    article         LONGTEXT,
    link            VARCHAR(255),
    creator         VARCHAR(255)        DEFAULT 'The Committee on Ways and Means',
    type            VARCHAR(255)        DEFAULT 'press release',
    country         VARCHAR(255)        DEFAULT 'US',
    date            DATETIME,
    dirty_news      TINYINT(1)          DEFAULT FALSE,
    with_table      TINYINT(1)          DEFAULT FALSE,
    data_source_url VARCHAR(255)        DEFAULT 'https://waysandmeans.house.gov/media-center/press-releases',
    created_by      VARCHAR(255)        DEFAULT 'Eldar Mustafaiev',
    created_at      DATETIME            DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY      link (link)
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;