create table us_court_cases.NY_case_info
(
    id                        bigint auto_increment
        primary key,
    court_name                varchar(255)                        null,
    court_state               varchar(255)                        null,
    court_type                varchar(255)                        null,
    case_name                 text                                null,
    case_id                   varchar(255)                        not null,
    case_filed_date           date                                null,
    case_description          varchar(2048)                       null,
    case_type                 varchar(255)                        null,
    disposition_or_status     varchar(2048)                       null,
    status_as_of_date         varchar(1024)                       null,
    judge_name                varchar(255)                        null,
    scrape_dev_name           varchar(255)                        null,
    data_source_url           varchar(255)                        not null,
    created_at                timestamp default CURRENT_TIMESTAMP not null,
    updated_at                timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    scrape_frequency          varchar(255)                        null,
    last_scrape_date          date                                null,
    next_scrape_date          date                                null,
    expected_scrape_frequency varchar(255)                        null,
    pl_gather_task_id         int                                 null,
    court_id                  int                                 null,
    md5_hash                  varchar(50)                         null,
    INDEX `court_id` (`court_id`),
    INDEX `md5_hash` (`md5_hash`),
    constraint uniques_data
        unique (case_id, data_source_url)
)
    collate = utf8mb4_unicode_520_ci;



