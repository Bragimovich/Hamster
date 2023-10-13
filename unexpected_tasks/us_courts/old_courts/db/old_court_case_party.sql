create table us_court_cases.old_court_case_party
(
    id                    bigint auto_increment
        primary key,
    court_id              int                                   null,
    case_id           varchar(255)                           not null,
    party_name        varchar(1024)                          null,
    party_type        varchar(80)                            null,
    party_law_firm    varchar(255)                           null,
    party_address     varchar(255)                           null,
    party_city        varchar(255)                           null,
    party_state       varchar(255)                           null,
    party_zip         varchar(255)                           null,
    party_description text                                   null,
    is_lawyer         tinyint(1)   default 0                 null,
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