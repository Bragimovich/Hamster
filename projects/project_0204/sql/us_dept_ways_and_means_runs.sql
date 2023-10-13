create table press_releases.us_dept_ways_and_means_runs
(
    id         bigint auto_increment
        primary key,
    status     varchar(255) default 'processing'        null,
    created_by varchar(255) default 'Khalikov R.' null,
    created_at datetime     default CURRENT_TIMESTAMP   null,
    updated_at timestamp    default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP
)
    collate = utf8mb4_unicode_520_ci;

create index status_idx
    on press_releases.us_dept_ways_and_means_runs (status);
