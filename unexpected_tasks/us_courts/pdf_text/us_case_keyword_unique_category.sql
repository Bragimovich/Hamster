create table us_courts_analysis.us_case_keyword_unique_category
(
    id                  bigint auto_increment
        primary key,
    unique_category_id  bigint                                                                                                                         null,
    court_id int,
    case_id            varchar(255)                                                                                                                   null,

    constraint unique_row
        unique (unique_category_id, court_id, case_id)
)
    collate = utf8mb4_unicode_520_ci;


