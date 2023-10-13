create table us_court_cases.old_court_case_activities
(
    id                    bigint auto_increment
        primary key,
    court_id              int                                   null,
    case_id         varchar(255)                           not null,
    activity_date   varchar(255)                           null,
    activity_decs   mediumtext                             null,
    activity_type   varchar(50)                            null,
    activity_pdf    varchar(511)                           null,
    data_source_url       varchar(255)                           null,
    created_by            varchar(255)                           null,
    created_at            datetime     default CURRENT_TIMESTAMP null,
    updated_at            timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    run_id                bigint                                 null,
    touched_run_id        bigint                                 null,
    deleted               tinyint(1)   default 0                 null,
    md5_hash              varchar(255)                           null,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `deleted` (`deleted`),
    INDEX `touched_run_id` (`touched_run_id`),
    constraint md5
        unique (md5_hash)
);