create table crime_perps__step_1.il_kane__arrestee_addresses
(
    id              bigint auto_increment
        primary key,
    arrestee_id     bigint                                 null,
    full_address    varchar(255)                           null,
    street_address  varchar(255)                           null,
    unit_number     varchar(255)                           null,
    city            varchar(255)                           null,
    county          varchar(255)                           null,
    state           varchar(255)                           null,
    zip             varchar(255)                           null,
    lan             varchar(255)                           null,
    lon             varchar(255)                           null,
    data_source_url text                                   null,
    created_by      varchar(255) default 'Maxim G'        null,
    created_at      datetime     default CURRENT_TIMESTAMP null,
    updated_at      datetime     default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    run_id        bigint,
    touched_run_id        bigint,
    deleted         tinyint(1)   default 0                 null,
    md5_hash        varchar(255)                           null,
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
);