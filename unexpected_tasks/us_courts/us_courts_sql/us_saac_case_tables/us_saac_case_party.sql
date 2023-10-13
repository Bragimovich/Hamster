use us_court_cases;
create table us_saac_case_party
(
    id                    bigint auto_increment
        primary key,
    court_id              smallint                              null,
    case_id               varchar(100)                          null,

    is_lawyer         int                                    null,
    party_name        varchar(255)                           null,
    party_type        varchar(255)                           null,
    party_law_firm    varchar(255)                           null,
    party_address     varchar(255)                           null,
    party_city        varchar(255)                           null,
    party_state       varchar(255)                           null,
    party_zip         varchar(255)                           null,
    party_description text                                   null,

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