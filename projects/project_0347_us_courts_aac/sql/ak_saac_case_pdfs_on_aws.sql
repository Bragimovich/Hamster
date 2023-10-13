create table us_court_cases.ak_saac_case_pdfs_on_aws
(
    id               int auto_increment primary key,
    run_id           bigint                                 null,
    court_id         varchar(255)                           null,
    case_id          varchar(255)                           null,
    source_type      varchar(255)                           null,
    aws_link         varchar(255)                           null,
    source_link      varchar(255)                           null,
    data_source_url  varchar(255)                           null,
    created_by       varchar(255) default 'Alim L.'         null,
    created_at       datetime     default CURRENT_TIMESTAMP null,
    updated_at       timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    touched_run_id   bigint                                 null,
    deleted          tinyint(1)   default 0                 null,
    md5_hash         varchar(255)                           null
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;