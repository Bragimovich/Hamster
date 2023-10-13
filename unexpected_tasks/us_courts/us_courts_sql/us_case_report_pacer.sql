use us_courts;
create table us_case_report_pacer
(
    id         bigint auto_increment primary key,
    court_id         varchar(255)                         null,
    case_id          varchar(255)                         null,
    case_name         text                         null,
    filename_summary     varchar(500)                         null,
    top5_matches_summary   text null,

    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `case_id` (`case_id`),
    INDEX `court_id` (`court_id`)
)
    collate = utf8mb4_unicode_520_ci;





update us_case_report_pacer p
    inner join us_case_info i on
    p.case_id = i.case_id
    set p.case_name = i.case_name WHERE p.case_name is null


UPDATE us_case_report_pacer SET case_name=null where case_name like 'Eastern District of New York%'


SELECT case_id, case_name from us_case_report_pacer where case_name like 'Eastern District of New York%'



# Take random 200 rows

SELECT a.case_id, i.case_name, a.court_id, t.court_name, a.activity_decs from us_case_activities a
    inner join us_case_info i on a.case_id=i.case_id
    inner join us_courts_table t on t.court_id=a.court_id
WHERE a.court_id in
      (select court_id from us_courts_table where is_pacer=1)
  AND activity_decs like '%complaint%' ORDER BY RAND() limit 200



SELECT court_id,  count(*), YEAR(case_filed_date) from us_case_info where YEAR(case_filed_date)=2017 and court_id in (SELECT court_id from us_courts_table where is_pacer=1) group by court_id

SELECT count(*)/22 from us_case_info where YEAR(case_filed_date)=2020 and court_id in (SELECT court_id from us_courts_table where is_pacer=1)