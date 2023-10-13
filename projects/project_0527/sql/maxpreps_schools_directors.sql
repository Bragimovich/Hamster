create table maxpreps_schools_directors
(
    id                bigint auto_increment primary key,
    `name`            varchar(255)                          null,

    run_id            bigint                                null,
    deleted           tinyint(1)  default 0                 null,
    data_source_url   varchar(255)                          null,
    md5_hash          varchar(32)                           null,
    created_by        varchar(20) default 'Eldar Eminov'    null,
    created_at        datetime    default CURRENT_TIMESTAMP null,
    updated_at        timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    UNIQUE KEY `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;