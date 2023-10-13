create table litigations.cases_judges
(
    case_id    bigint                                 not null,
    judge_id   bigint                                 not null,
    removed    boolean                  default false not null,
    created_by varchar(255)                           not null,
    created_at timestamp,
    updated_at timestamp
);

alter table us_courts.cases_judges
    owner to lmaloney;

create index idx_5284733_case_id
    on us_courts.cases_judges (case_id);

create index idx_5284733_fk_cases_judges_2_idx
    on us_courts.cases_judges (judge_id);

create unique index idx_5284733_index1
    on us_courts.cases_judges (case_id, judge_id);

