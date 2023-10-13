create table usa_raw.us_courts_history_runs
(
    id         bigint auto_increment        primary key,
    run_id     bigint,
    court_id    int,
    status     varchar(255) default 'processing'          null,
    info_status varchar(255) default 'processing'          null,
    activities_status varchar(255) default 'processing'          null,
    party_status varchar(255) default 'processing'          null,
    lawyer_status varchar(255) default 'processing'          null,
    created_by varchar(255) default '-' null,
    created_at datetime     default CURRENT_TIMESTAMP     null,
    updated_at timestamp    default CURRENT_TIMESTAMP     not null on update CURRENT_TIMESTAMP
);


create table usa_raw.us_case_info_history
(
    id                        bigint auto_increment              primary key,
    court_id                 varchar(255)                           null,
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
    created_at               datetime     default CURRENT_TIMESTAMP null,
    updated_at               timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    scrape_frequncy          varchar(255) default 'daily'           null,
    last_scrape_date         datetime                               null,
    next_scrape_date         datetime                               null,
    expected_scrape_frequncy varchar(255) default 'daily'           null,
    pl_gather_task_id        int                                    null,

    run_id                   bigint                                 null,
    touched_run_id           bigint                                 null,
    deleted                  tinyint(1)   default 0                 null,
    md5_hash                 varchar(255)                           null,
    constraint md5_hash
        unique (md5_hash)
)
    collate = utf8mb4_unicode_520_ci;

create index md5_hash
    on usa_raw.us_case_info_history (md5_hash);

create table usa_raw.us_case_party_history
(
    id                        bigint auto_increment              primary key,
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

    run_id                   bigint                                 null,
    touched_run_id           bigint                                 null,
    deleted                  tinyint(1)   default 0                 null,
    md5_hash                 varchar(255)                           null,

    constraint md5_hash
        unique (md5_hash)
)
    collate = utf8mb4_unicode_520_ci;

create index md5_hash
    on usa_raw.us_case_party_history (md5_hash);


create table usa_raw.us_case_activities_history
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
    md5_hash                  varchar(64) default ''                not null,

    run_id                   bigint                                 null,
    touched_run_id           bigint                                 null,
    deleted                  tinyint(1)   default 0                 null,
    constraint md5_hash
        unique (md5_hash)
)
    collate = utf8mb4_unicode_520_ci;

create index md5_hash
    on usa_raw.us_case_activities_history (md5_hash);

create table usa_raw.us_case_lawyer_history
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

    run_id                   bigint                                 null,
    touched_run_id           bigint                                 null,
    deleted                  tinyint(1)   default 0                 null,
    md5_hash                 varchar(255)                           null,

    constraint md5_hash
        unique (md5_hash)
)
    collate = utf8mb4_unicode_520_ci;

create index md5_hash
    on usa_raw.us_case_lawyer_history (md5_hash);

UPDATE usa_raw.us_case_party SET md5_hash=(MD5(CONCAT_WS('',court_id, case_number, party_name, party_type))) WHERE court_id>50 AND court_id<101
UPDATE usa_raw.us_case_party SET md5_hash=(MD5(CONCAT_WS('',court_id, case_number, party_name, party_type))) WHERE court_id>100;
UPDATE usa_raw.us_case_party SET md5_hash=(MD5(CONCAT_WS('',court_id, case_number, party_name, party_type))) WHERE court_id<11

UPDATE usa_raw.us_case_lawyer SET md5_hash=(MD5(CONCAT_WS('',court_id, case_number, defendant_lawyer, defendant_lawyer_firm, plantiff_lawyer, plantiff_lawyer_firm)) WHERE court_id<11