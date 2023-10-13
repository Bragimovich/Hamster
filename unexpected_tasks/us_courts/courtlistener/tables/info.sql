create table us_court_cases.cl_case_info
(
    id                    bigint auto_increment
        primary key,
    court_id              int                                  null,
    cl_court_id           varchar(50)                          null,
    raw_case_id           varchar(255)                         null,
    case_id               varchar(255)                         null,
    case_name             varchar(500)                         null,
    case_filed_date       datetime                             null,
    case_type             varchar(255)                         null,
    case_description      varchar(2047)                        null,
    disposition_or_status varchar(1000)                        null,
    status_as_of_date     varchar(511)                         null,
    judge_name            varchar(255)                         null,
    data_source_url       varchar(500)                         null,
    created_by            varchar(255)                         null,
    created_at            timestamp  default CURRENT_TIMESTAMP not null,
    updated_at            timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    md5_hash              varchar(255)                         null,
    deleted               tinyint(1) default 0                 null,
    run_id                bigint                               null,
    touched_run_id        bigint                               null,
    docket_id             bigint                               null,
    claster_id            bigint                               null,
    constraint md5
        unique (md5_hash),
    INDEX case_filed_date(case_filed_date),
    INDEX raw_case_id(raw_case_id),
    INDEX cl_court_id(cl_court_id),
    INDEX claster_id(claster_id),
    INDEX court_id(court_id),
    INDEX docket_id(docket_id),
    INDEX judge_name(judge_name),
    INDEX deleted(deleted)
) collate = utf8mb4_unicode_520_ci,
    COMMENT = 'Table for summarize all cases from courtlistener site with general view.
Made by Maxim G. (2022-10-26)';
