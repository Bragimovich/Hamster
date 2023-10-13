create table us_court_cases.ks_ac_case_activities
(
    id               int auto_increment primary key,
    court_id         int                                    null,
    case_id          varchar(255)                           null,
    activity_date    date                                   null,
    activity_desc    mediumtext                             null,
    activity_type    varchar(255)                           null,
    file             varchar(255)                           null,
    data_source_url  text                                   null,
    created_by       varchar(255) default 'Alim L.'         null,
    created_at       datetime     default CURRENT_TIMESTAMP null,
    updated_at       timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    run_id           bigint                                 null,
    touched_run_id   bigint                                 null,
    deleted          tinyint(1)   default 0                 null,
    md5_hash         varchar(255)                           null
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;