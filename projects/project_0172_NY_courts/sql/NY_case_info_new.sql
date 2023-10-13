create table us_court_cases.NY_case_info_new
(
    id                        bigint auto_increment
        primary key,
    court_id                  int                                 null,
    case_id                   varchar(255)                        not null,

    case_name                 varchar(1024)                       null,
    case_filed_date           date                                null,
    case_description          varchar(2048)                       null,
    case_type                 varchar(255)                        null,
    disposition_or_status     varchar(2048)                       null,
    status_as_of_date         varchar(1024)                       null,
    judge_name                varchar(255)                        null,

    data_source_url           varchar(255)                        not null,
    created_by                varchar(255)                        null,
    created_at                timestamp default CURRENT_TIMESTAMP not null,
    updated_at                timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    scrape_frequency          varchar(255)                        null,

    run_id                    BIGINT(20),
    touched_run_id            BIGINT(20),
    deleted                   TINYINT(1) default 0   ,

    md5_hash                  varchar(50)                         null,
    INDEX `court_id` (`court_id`),
    INDEX `md5_hash` (`md5_hash`),
    constraint uniques_data
        unique (case_id, data_source_url)
)
    collate = utf8mb4_unicode_520_ci;





INSERT INTO NY_case_info_new (court_id, case_id, case_name, case_filed_date, case_description,case_type,
                              disposition_or_status, status_as_of_date, judge_name, data_source_url, created_by,scrape_frequency, md5_hash)
SELECT court_id, case_id, case_name, case_filed_date, case_description,case_type,
       disposition_or_status, status_as_of_date, judge_name, data_source_url, scrape_dev_name, scrape_frequency, md5_hash from NY_case_info

