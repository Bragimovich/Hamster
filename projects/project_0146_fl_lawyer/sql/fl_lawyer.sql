use lawyer_status;
create table florida
(
    id                      int auto_increment
        primary key,

    bar_number              bigint                                    null,
    name                    varchar(255)                               null,
    link                    varchar(511)                               null,
    law_firm_name           varchar(1023)                                null,
    law_firm_address        varchar(2045)                                null,
    law_firm_zip            varchar(255)                               null,
    law_firm_county         varchar(255)                               null,
    state                   varchar(15)                                 null,
    phone                   varchar(255)                               null,
    email                   varchar(255)                               null,
    date_admitted           datetime                                 null,
    sections                mediumtext                          null,
    registration_status     varchar(255)                               null,


    data_source_url         varchar(255) default 'https://www.floridabar.org/directories/find-mbr/'                               null,
    created_by              varchar(30)  default 'Maxim G' null,
    created_at              datetime     default CURRENT_TIMESTAMP   null,
    updated_at              timestamp    default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
    run_id                  bigint                                   null,
    touched_run_id          bigint                                   null,
    deleted                 tinyint(1)         default 0               null,
    md5_hash                varchar(255)                               null,
    scrape_frequency        varchar(100)    default 'Weekly'            null
);

create index bar_number
    on lawyer_status.florida (bar_number);

create index touched_run_id
    on lawyer_status.florida (touched_run_id);