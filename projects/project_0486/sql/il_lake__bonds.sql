create table il_lake__bonds
(
    id                     bigint auto_increment
        primary key,
    run_id                 bigint                                   null,
    arrest_id              bigint                                   null,
    bond_category          varchar(255)                             null,
    bond_number            varchar(255)                             null,
    bond_type              varchar(255)                             null,
    bond_amount            varchar(255)                             null,
    paid                   int                                      null,
    made_bond_release_date date                                     null,
    made_bond_release_time time                                     null,
    data_source_url        text                                     null,
    created_by             varchar(255) default 'Mikhail Golovanov' null,
    created_at             datetime     default CURRENT_TIMESTAMP   null,
    updated_at             datetime     default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
    touched_run_id         bigint                                   null,
    deleted                tinyint(1)   default 0                   null,
    md5_hash               varchar(255)                             null,
    charge_id              bigint                                   null,
    constraint md5
        unique (md5_hash)
);

create index deleted
    on il_lake__bonds (deleted);

create index run_id
    on il_lake__bonds (run_id);

create index touched_run_id
    on il_lake__bonds (touched_run_id);

