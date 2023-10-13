use us_court_cases;
CREATE TABLE ca_saac_additional_info
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

CREATE TABLE ca_saac_case_activities
(
    id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id int,
    case_id varchar(255),
    activity_date date,
    activity_desc mediumtext,
    activity_type varchar(255),
    file varchar(255) null,
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
    COMMENT = 'Case activity info for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

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
    scrape_frequency varchar(255) NULL DEFAULT 'weekly',
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

CREATE TABLE ca_saac_case_party
(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id int,
    case_id varchar(255),
    is_lawyer boolean,
    party_name varchar(255),
    party_type varchar(2000),
    party_law_firm varchar(255),
    party_address varchar(255),
    party_city varchar(255),
    party_state varchar(255),
    party_zip varchar(255),
    party_description text,
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
    COMMENT = 'Case party info for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE ca_saac_case_pdfs_on_aws
(
    id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id int,
    case_id varchar(255),
    source_type varchar(255) DEFAULT 'info',
    aws_link varchar(255),
    source_link varchar(255),

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
    COMMENT = 'Pdfs for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE ca_saac_case_relations_activity_pdf
(
    id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    case_activities_md5 varchar(255),
    case_pdf_on_aws_md5 varchar(255),

    data_source_url VARCHAR(600) DEFAULT 'https://appellatecases.courtinfo.ca.gov/',
    created_by VARCHAR(255) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint                                 null,
    touched_run_id        bigint                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(255)                           null,
    INDEX `deleted` (`deleted`),
    INDEX `touched_run_id` (`touched_run_id`),
    UNIQUE KEY `md5_hash` (`md5_hash`)
)
    COMMENT = 'Relations Activities and Pdfs for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE ca_saac_case_relations_info_pdf
(
    id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    case_info_md5 varchar(255),
    case_pdf_on_aws_md5 varchar(255),
    data_source_url VARCHAR(600) DEFAULT 'https://appellatecases.courtinfo.ca.gov/',
    created_by VARCHAR(255) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint                                 null,
    touched_run_id        bigint                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(255)                           null,
    INDEX `deleted` (`deleted`),
    INDEX `touched_run_id` (`touched_run_id`),
    UNIQUE KEY `md5_hash` (`md5_hash`)
)
    COMMENT = 'Relations Activities and Pdfs for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE ca_saac_runs
(
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(255) DEFAULT 'processing',
    created_by VARCHAR(255) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX status_idx (status)
)
    COMMENT = 'Script runs for California Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;