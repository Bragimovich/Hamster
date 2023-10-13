create table us_court_cases.NY_case_lawyer
(
    id                        bigint auto_increment
        primary key,
    case_number               varchar(70)                            not null,
    defendant_lawyer          varchar(255) default ''                not null,
    defendant_lawyer_firm     varchar(150) default ''                not null,
    plantiff_lawyer           varchar(255) default ''                not null,
    plantiff_lawyer_firm      varchar(150) default ''                not null,
    scrape_dev_name           varchar(255)                           null,
    data_source_url           varchar(200)                           not null,
    created_at                timestamp    default CURRENT_TIMESTAMP not null,
    updated_at                timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    scrape_frequency          varchar(255)                           null,
    last_scrape_date          date                                   null,
    next_scrape_date          date                                   null,
    expected_scrape_frequency varchar(255)                           null,
    pl_gather_task_id         int                                    null,
    court_id                  int                                    null,
    md5_hash                  varchar(50)  default ''                not null,
    INDEX `md5_hash` (`md5_hash`),
    constraint unique_records
        unique (case_number, defendant_lawyer, plantiff_lawyer, plantiff_lawyer_firm, defendant_lawyer_firm,
                data_source_url)
)
    collate = utf8mb4_unicode_520_ci;


