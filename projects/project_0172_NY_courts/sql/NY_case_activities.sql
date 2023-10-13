create table us_court_cases.NY_case_activities
(
    id                        bigint auto_increment
        primary key,
    case_id                   varchar(70)                           not null,
    activity_date             date        default '0000-00-00'      not null,
    activity_decs             mediumtext                            not null,
    activity_type             varchar(30) default ''                not null,
    activity_pdf              varchar(511)                          null,
    scrape_dev_name           varchar(255)                          null,
    data_source_url           varchar(255)                          null,
    created_at                timestamp   default CURRENT_TIMESTAMP not null,
    updated_at                timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    scrape_frequency          varchar(255)                          null,
    last_scrape_date          date                                  null,
    next_scrape_date          date                                  null,
    expected_scrape_frequency varchar(255)                          null,
    pl_gather_task_id         int                                   null,
    court_id                  int                                   null,
    file                      varchar(80) default ''                not null,
    md5_hash                  varchar(32) default ''                not null,
    INDEX `md5_hash` (`md5_hash`),
    constraint unique_records
        unique (case_id, activity_decs, activity_type, activity_date, file, md5_hash)
)
    collate = utf8mb4_unicode_520_ci;


