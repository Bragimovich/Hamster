use us_court_cases;
CREATE TABLE ca_saac_case_additional_info
(
    id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id int,
    case_id varchar(255),
    lower_court_name varchar(255),
    lower_case_id varchar(255),
    lower_judge_name varchar(255),
    lower_judgement_date date,
    lower_link varchar(600),
    disposition varchar(255),
    data_source_url VARCHAR(600) DEFAULT 'https://appellatecases.courtinfo.ca.gov/',
    created_by VARCHAR(255) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint                                 null,
    touched_run_id        bigint                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(255)                           null,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `deleted` (`deleted`),
    INDEX `touched_run_id` (`touched_run_id`),
    UNIQUE KEY `md5_hash` (`md5_hash`)
)
    COMMENT = 'additional info for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;