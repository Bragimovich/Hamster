create table litigations.courts
(
    id          int,
    external_id int default 0                 not null,
    is_appealed bool   default False                 not null,
    name        varchar(255)                           null,
    state       varchar(2)                             null,
    type        varchar(64)                            null,
    sub_type    varchar(64)                            null,
    court_group varchar(255)                           null,
    limpar_uuid varchar(255)                           null,
    created_by  varchar(255)                           not null,
    created_at  date  ,
    updated_at  date  ,
    constraint external_id_UNIQUE
        unique (external_id),
    constraint id_UNIQUE
        unique (id),
    constraint limpar_uuid_UNIQUE
        unique (limpar_uuid)
);


COPY litigations.courts FROM '/Users/magusch/staging/courts.csv' DELIMITER ',' CSV HEADER
