create table us_court_cases.NY_case_index
(
    id                    bigint auto_increment
        primary key,
    court_id              int                                  null,
    case_id               varchar(255)                         not null,
    docket_id               varchar(255)                        null,

    case_filed_date       date                                 null,
    done                tinyint(1) default 0                 null,
    data_source_url       varchar(255)                         not null,
    created_by            varchar(255)             default     'Maxim G',
    created_at            timestamp  default CURRENT_TIMESTAMP not null,
    updated_at            timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `court_id` (`court_id`),
    INDEX `docket_id` (`docket_id`),
    INDEX `case_id` (`case_id`),
    INDEX `done` (`done`),
    constraint uniques_data
        unique (case_id, docket_id)
)
    collate = utf8mb4_unicode_520_ci
comment = 'General table for all cases'


