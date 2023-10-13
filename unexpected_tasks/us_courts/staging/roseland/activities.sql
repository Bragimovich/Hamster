create table litigations.activities
(
    id             bigint,
    external_id    bigint       not null,
    external_table varchar(255),
    court_id       bigint,
    case_id        bigint       not null,
    date           date,
    description    text,
    type           varchar(128),
    pdf            varchar(255),
    created_by     varchar(255) not null,
    created_at     timestamp with time zone default CURRENT_TIMESTAMP,
    updated_at     timestamp with time zone
);


create index idx_5280349_case_id
    on litigations.activities (case_id);

create index idx_5280349_court_id
    on litigations.activities (court_id);

create unique index idx_5280349_external_id_table_unique
    on litigations.activities (external_id, external_table);

create index idx_5280349_fk_activities_1_idx
    on litigations.activities (case_id);

create unique index idx_5280349_id_unique
    on litigations.activities (id);

create unique index idx_5280349_primary
    on litigations.activities (id);

