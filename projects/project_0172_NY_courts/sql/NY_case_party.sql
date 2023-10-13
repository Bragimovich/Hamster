create table us_court_cases.NY_case_party
(
    id                        bigint auto_increment
        primary key,
    case_number               varchar(70)                           not null,
    party_name                varchar(1024)                         not null,
    party_type                varchar(80) default ''                not null,
    party_address             varchar(255)                          null,
    party_city                varchar(255)                          null,
    party_state               varchar(255)                          null,
    party_zip                 varchar(255)                          null,
    scrape_dev_name           varchar(255)                          null,
    data_source_url           varchar(200)                          not null,
    created_at                timestamp   default CURRENT_TIMESTAMP not null,
    updated_at                timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    scrape_frequency          varchar(255)                          null,
    last_scrape_date          date                                  null,
    next_scrape_date          date                                  null,
    expected_scrape_frequency varchar(255)                          null,
    pl_gather_task_id         int                                   null,
    court_id                  int                                   null,
    law_firm                  varchar(255)                          null,
    is_lawyer                 tinyint(1)  default 0                 null,
    party_description         varchar(2048)                         null,
    md5_hash                  varchar(50)                           null,
    INDEX `case_number` (`case_number`),
    INDEX `md5_hash` (`md5_hash`),
    constraint unique_data
        unique (case_number, party_name, data_source_url, party_type)
)
    collate = utf8mb4_unicode_520_ci;

