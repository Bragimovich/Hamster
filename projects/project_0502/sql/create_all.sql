use us_court_cases;
CREATE TABLE sc_saac_case_additional_info
(
    id              bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id smallint(6) ,
    case_id varchar(100) ,
    lower_court_name varchar(255),
    lower_case_id varchar(255),
    lower_judge_name text,
    lower_judgement_date date,
    lower_link varchar(255),
    disposition varchar(255),
    data_source_url VARCHAR(255) DEFAULT 'https://ctrack.sccourts.org/public/caseSearch.do',
    created_by VARCHAR(20) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint(20)                                 null,
    touched_run_id        bigint(20)                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(32)                           null,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `deleted` (`deleted`),
    INDEX `md5` (`md5_hash`),
    UNIQUE KEY `md5_hash` (`md5_hash`)
)
    COMMENT = 'additional info for South Carolina Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE sc_saac_case_activities
(
    id              bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id smallint(6),
    case_id varchar(100),
    activity_date date,
    activity_desc text,
    activity_type varchar(1023),
    file text null,
    data_source_url VARCHAR(255) DEFAULT 'https://ctrack.sccourts.org/public/caseSearch.do',
    created_by VARCHAR(20) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint(20)                                 null,
    touched_run_id        bigint(20)                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(32)                           null,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `deleted` (`deleted`),
    INDEX `md5` (`md5_hash`),
    UNIQUE KEY `md5_hash` (`md5_hash`)
)
    COMMENT = 'Case activity info for South Carolina Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE sc_saac_case_info
(
    id bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id smallint(6),
    case_id varchar(100),
    case_name varchar(1500),
    case_filed_date date,
    case_type varchar(2000),
    case_description varchar(6000),
    disposition_or_status varchar(100),
    status_as_of_date varchar(255),
    judge_name varchar(255),
    lower_court_id smallint(6),
    lower_case_id varchar(1000),
    data_source_url VARCHAR(255) DEFAULT 'https://ctrack.sccourts.org/public/caseSearch.do',
    created_by VARCHAR(20) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint(20)                                 null,
    touched_run_id        bigint(20)                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(32)                           null,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `deleted` (`deleted`),
    INDEX `md5` (`md5_hash`),
    UNIQUE KEY `md5_hash` (`md5_hash`)
)
    COMMENT = 'Case info for South Carolina Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE sc_saac_case_party
(
    id bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id smallint(6),
    case_id varchar(100),
    is_lawyer int(11),
    party_name varchar(255),
    party_type varchar(255),
    party_law_firm varchar(1023),
    party_address varchar(500),
    party_city varchar(255),
    party_state varchar(255),
    party_zip varchar(255),
    party_description text,
    data_source_url VARCHAR(255) DEFAULT 'https://ctrack.sccourts.org/public/caseSearch.do',
    created_by VARCHAR(20) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint(20)                                 null,
    touched_run_id        bigint(20)                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(32)                           null,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `deleted` (`deleted`),
    INDEX `md5` (`md5_hash`),
    UNIQUE KEY `md5_hash` (`md5_hash`)
)
    COMMENT = 'Case party info for South Carolina Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE sc_saac_case_pdfs_on_aws
(
    id              bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id smallint(6),
    case_id varchar(100),
    source_type varchar(255) DEFAULT 'activities',
    aws_link varchar(255),
    source_link varchar(255),

    data_source_url VARCHAR(255) DEFAULT 'https://ctrack.sccourts.org/public/caseSearch.do',
    created_by VARCHAR(20) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint(20)                                 null,
    touched_run_id        bigint(20)                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(32)                           null,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `deleted` (`deleted`),
    INDEX `md5` (`md5_hash`),
    UNIQUE KEY `md5_hash` (`md5_hash`)
)
    COMMENT = 'Pdfs for South Carolina Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE sc_saac_case_relations_activity_pdf
(
    id              bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    court_id smallint(6),
    case_activities_md5 varchar(32),
    case_pdf_on_aws_md5 varchar(32),
    created_by VARCHAR(255) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    run_id                bigint                                 null,
    touched_run_id        bigint                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(32)                           null,
    INDEX `uniq_data` (`case_activities_md5`, `case_pdf_on_aws_md5`),
    INDEX `court_id` (`court_id`),
    UNIQUE KEY `unique_data` (`case_activities_md5`, `case_pdf_on_aws_md5`)
)
    COMMENT = 'Relations Activities and Pdfs for South Carolina Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE sc_saac_case_runs
(
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(255) DEFAULT 'processing',
    created_by VARCHAR(255) DEFAULT 'Pospelov Vyacheslav',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX status_idx (status)
)
    COMMENT = 'Script runs for South Carolina Supreme and Appellate Courts'
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;