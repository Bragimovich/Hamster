use us_courts;
create table us_case_report
(
    id         bigint auto_increment primary key,
    case_id          varchar(255)                         null,
    case_name         text                         null,
    link_pdf_summary     varchar(500)                         null,
    top5_matches_summary   text null,
    link_pdf_complaint     varchar(500)                         null,
    top5_matches_complaint text null,

    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `case_id` (`case_id`),
    INDEX `link_pdf_summary` (`link_pdf_summary`),
    INDEX `case_name` (`case_name`)
)
    collate = utf8mb4_unicode_520_ci;




update us_case_report_aws p
    inner join us_case_info i on
    p.case_id = i.case_id
    set p.case_name = i.case_name WHERE p.case_name is null


update us_case_report_aws a
    inner join us_courts_table ct on
    a.court_id = ct.court_id
    set a.court_name = ct.court_name WHERE a.court_name is null

