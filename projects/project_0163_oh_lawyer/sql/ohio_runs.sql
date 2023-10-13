create table lawyer_status.ohio_runs
(
    id         bigint auto_increment
        primary key,
    status     varchar(255) default 'processing'        null,
    created_by varchar(255) default 'Maxim G' null,
    created_at datetime     default CURRENT_TIMESTAMP   null,
    updated_at timestamp    default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
    INDEX status_idx (status)
)
    collate = utf8mb4_unicode_520_ci;
