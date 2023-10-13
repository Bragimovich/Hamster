use us_court_cases;
CREATE TABLE ca_saac_case_info
(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id int,
    case_id varchar(255),
    case_name text,
    case_filed_date date,
    case_type varchar(255),
    case_description varchar(255),
    disposition_or_status varchar(255),
    status_as_of_date varchar(255),
    judge_name varchar(255),
    lower_court_id varchar(255),
    lower_case_id varchar(255),
    judge_name varchar(255) NULL,
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
    COMMENT = 'Case info for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;