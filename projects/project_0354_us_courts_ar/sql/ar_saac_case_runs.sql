create table us_court_cases.ar_saac_case_runs
(
    id         bigint auto_increment
        primary key,
    status     varchar(255) default 'processing'        null,
    created_by varchar(255) default 'Maxim G' null,
    created_at timestamp    default CURRENT_TIMESTAMP   not null,
    updated_at timestamp    default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
    INDEX `status` (status)
);

