create table us_court_cases.NY_case_activities_new
(
    id                        bigint auto_increment
        primary key,
    case_id                   varchar(70)                           not null,
    court_id                  int                                   null,

    activity_date             varchar(255)                          null,
    activity_decs             mediumtext                            null,
    activity_type             varchar(50)                           null,
    activity_pdf              varchar(511)                          null,
    file                      varchar(80)                           null,

    data_source_url           varchar(255)                          null,
    created_by                varchar(255)                          null,
    created_at                timestamp   default CURRENT_TIMESTAMP not null,
    updated_at                timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    scrape_frequency          varchar(255)                          null,


    run_id                    BIGINT(20),
    touched_run_id            BIGINT(20),
    deleted                   TINYINT(1) default 0,

    md5_hash                  varchar(32) default ''                not null,
    INDEX `md5_hash` (`md5_hash`)
)
    collate = utf8mb4_unicode_520_ci;


INSERT INTO NY_case_activities_new (court_id, case_id, activity_date, activity_decs, activity_pdf, activity_type,
                                    file, data_source_url, created_by,scrape_frequency, md5_hash)
SELECT court_id, case_id, activity_date, activity_decs, activity_pdf, activity_type,
       file, data_source_url, scrape_dev_name, scrape_frequency, md5_hash from NY_case_activities



