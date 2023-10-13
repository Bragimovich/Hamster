create table maxpreps_schools
(
    id                bigint auto_increment primary key,

    `name`            varchar(255)                          null,
    address           varchar(255)                          null,
    address2          varchar(255)                          null,
    city              varchar(255)                          null,
    `state`           varchar(2)                            null,
    zip               varchar(255)                          null,
    latitude          varchar(20)                           null,
    longitude         varchar(20)                           null,
    phone             varchar(255)                          null,
    mascot            varchar(255)                          null,
    colors            varchar(255)                          null,
    school_type       varchar(255)                          null,
    director_id       int                                   null,

    run_id            bigint                                null,
    deleted           tinyint(1)  default 0                 null,
    data_source_url   varchar(255)                          null,
    md5_hash          varchar(32)                           null,
    created_by        varchar(20) default 'Eldar Eminov'    null,
    created_at        datetime    default CURRENT_TIMESTAMP null,
    updated_at        timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    UNIQUE KEY `md5_hash` (`md5_hash`),
    INDEX `data_source_url` (`data_source_url`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;