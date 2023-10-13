
create table us_courts_staging.court_addresses
(
    court_id          int unsigned auto_increment
        primary key,
    external_id int unsigned default 0                 not null comment 'id from us_cases.us_courts_table
0 if such court wasn''t created in external table, and was received from some superior court''s case',
    name        varchar(255)                           not null,
    state       varchar(64)                            not null,
    street_address        varchar(1023)                not null,
    city        varchar(100)                           not null,
    zip        varchar(100)                            not null,
    latitude        varchar(100)                           null,
    longitude        varchar(100)                          null,

    created_by  varchar(255)                           not null,
    created_at  datetime     default CURRENT_TIMESTAMP null,
    updated_at  datetime     default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP

)
    collate = utf8mb4_unicode_520_ci;

