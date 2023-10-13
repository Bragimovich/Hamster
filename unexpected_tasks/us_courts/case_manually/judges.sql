create table us_courts.us_case_pipeline2_judges
(
    id         bigint auto_increment
        primary key,
    court_id   bigint                              null,
    judge_name varchar(255)                        null,
    first_name varchar(64)                        null,
    middle_name varchar(64)                        null,
    last_name varchar(64)                        null,
    suffix varchar(64)                        null,
    created_at timestamp default CURRENT_TIMESTAMP not null,
    updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint court_id
        unique (court_id, judge_name)
)
    collate = utf8mb4_unicode_520_ci;


INSERT IGNORE INTO us_courts_staging.cases_judges (case_id, judge_id, created_by)
SELECT c.id, j.id, 'Maxim G.' FROM us_case_info i
join us_pipeline2_judges pj on i.judge_name = pj.judge_name
join us_courts_staging.judges j on j.first_name = pj.first_name and j.last_name = pj.last_name
join us_courts_staging.cases c on c.raw_id = i.case_id;

INSERT INTO us_judges_mbo (court_id, judge_first_name, judge_last_name, judge_middle_name, judge_suffix)
SELECT court_id, first_name, last_name, middle_name, suffix from us_pipeline2_judges pj
where CONCAT(pj.first_name, pj.last_name) not in (SELECT CONCAT(first_name, last_name) from us_courts_staging.judges)

