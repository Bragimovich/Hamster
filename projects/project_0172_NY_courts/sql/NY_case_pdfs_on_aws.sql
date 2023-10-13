create table us_court_cases.NY_case_pdfs_on_aws
(
    id              int auto_increment
        primary key,
    court_id        int                                    null,
    case_id         varchar(255)                           null,
    source_type     varchar(255)                           null,
    aws_link        varchar(255)                           null,
    aws_html_link   varchar(255)                           null,
    source_link     varchar(255)                           null,
    md5_hash        varchar(255)                           null,
    run_id          int                                    null,
    deleted         int          default 0                 null,
    data_source_url varchar(511)                           null,
    touched_run_id  int                                    null,
    created_by      varchar(255) default 'Maxim G'           null,
    created_at      datetime     default CURRENT_TIMESTAMP null,
    updated_at      timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX court_id (court_id),
    INDEX case_id (case_id),
    INDEX deleted (deleted),
    constraint unique_data
        unique (md5_hash)
)   collate = utf8mb4_unicode_520_ci,
    comment = 'Table for PDFS for NY court'
;


