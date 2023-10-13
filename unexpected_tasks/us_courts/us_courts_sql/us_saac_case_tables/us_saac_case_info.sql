use us_court_cases;
create table us_saac_case_info
(
    id                    bigint auto_increment
        primary key,
    court_id              smallint                              null,
    case_id               varchar(100)                          null,
    case_name             varchar(200)                          null,
    case_filed_date       datetime                              null,
    case_type             varchar(2000)                         null,
    case_description      varchar(6000)                         null,
    disposition_or_status varchar(100)                          null,
    status_as_of_date     varchar(255)                          null,
    judge_name            varchar(255)                          null,
    lower_court_id        smallint                              null,
    lower_case_id         varchar(1000)                         null,
    md5_hash              varchar(32)                           null,
    created_by            varchar(20) default    null,
    created_at            datetime    default CURRENT_TIMESTAMP null,
    updated_at            timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    data_source_url       varchar(255)                          null,
    run_id                bigint                                null,
    touched_run_id        bigint                                null,
    deleted               tinyint(1)  default 0                 null,
    constraint md5
        unique (md5_hash),
    INDEX `case_id` (`case_id`),
    INDEX `court_id` (`court_id`),
    INDEX `deleted` (`deleted`)
);