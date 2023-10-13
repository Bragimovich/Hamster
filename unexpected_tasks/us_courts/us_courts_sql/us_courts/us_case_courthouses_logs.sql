use us_courts_analysis;
create table us_case_courthouse_logs
(
    id                    bigint auto_increment primary key,

    object_type             varchar(255)                          null,
    action                varchar(255)                         null,
    message               varchar(511)                         null,

    table_name             varchar(255)                          null,
    column_name             varchar(255)                          null,
    column_type             varchar(255)                          null,

    created_at            datetime    default CURRENT_TIMESTAMP null
);