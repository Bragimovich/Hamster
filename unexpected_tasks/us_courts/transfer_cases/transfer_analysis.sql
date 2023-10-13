create table us_courts_analysis.transfer_cases_table
(
    court_id         bigint primary key,
    court_name_id       varchar(30),
    court_name varchar(255),
    info        bigint,
    party        bigint,
    activities        bigint,
    additional_info        bigint,
    consolidations        bigint,
    pdfs_on_aws        bigint,


    created_by         varchar(255)                       not null,
    created_at         datetime default CURRENT_TIMESTAMP null,
    updated_at         datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP

)
    collate = utf8mb4_unicode_520_ci;