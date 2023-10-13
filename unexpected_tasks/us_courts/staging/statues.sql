create table us_courts.us_case_statuses
(
    id                             bigint auto_increment
        primary key,
    original_status                varchar(255)                             not null,
    new_status                     varchar(255)                             null,
    in_work                     boolean default 1,
    md5_hash                     varchar(255)                             null,

    constraint md5
        unique (md5_hash),
        INDEX original_status(original_status),
    INDEX new_status(new_status)
)
    collate = utf8mb4_unicode_520_ci;



UPDATE us_courts_staging_working_copy.cases c
    join us_courts.us_case_statuses s on c.status = s.original_status
SET status = s.new_status
where s.new_status is not null;



SELECT status, count(*) FROM us_courts_staging_working_copy.cases
where status not in (SELECT original_status from us_courts.us_case_statuses)
group by status

