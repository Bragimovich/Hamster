create table us_courts_analysis.us_case_overall_data_analysis
(
    id                         bigint auto_increment
        primary key,
    court_id                   bigint                              null,
    court_name                 varchar(255)                        null,

    total_cases      bigint                              null,
    total_cases_with_lawyer_bio         bigint                              null,
    total_cases_with_judge_bio bigint                              null,
    total_cases_with_lawyer_and_judge bigint                              null,
    total_cases_with_conflict_of_interest bigint                              null,
    created_at                 datetime  default CURRENT_TIMESTAMP null,
    updated_at                 timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,


    constraint court_id
        unique (court_id)
);

