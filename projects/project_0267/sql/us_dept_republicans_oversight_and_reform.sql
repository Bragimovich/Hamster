CREATE TABLE us_dept_republicans_oversight_and_reform
(
    id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(255),
    teaser          TEXT,
    article         LONGTEXT,
    link            VARCHAR(255),
    creator         VARCHAR(255)        DEFAULT 'The Republicans Committee on Oversight and Reform',
    type            VARCHAR(255)        DEFAULT 'press release',
    country         VARCHAR(255)        DEFAULT 'US',
    date            DATETIME,
    dirty_news      TINYINT(1)          DEFAULT FALSE,
    with_table      TINYINT(1)          DEFAULT FALSE,
    data_source_url VARCHAR(255)        DEFAULT 'https://republicans-oversight.house.gov/release',
    created_by      VARCHAR(255)        DEFAULT 'Eldar Mustafaiev',
    created_at      DATETIME            DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY      link (link)
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;