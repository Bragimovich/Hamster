create table us_courts_analysis.us_case_types_rachelle_categorized
(
    id                bigint auto_increment
        primary key,
    court_id INT,
    count BIGINT(20),
    case_type          varchar(1023) null,
    priority          varchar(255)  null,
    general_category  varchar(255)  null,
    midlevel_category varchar(255)  null,
    specific_category varchar(255)  null,
    additional_category varchar(255)  null
)
    collate = utf8mb4_unicode_520_ci;

create index values
    on us_courts.us_case_types (`values`(500));


use us_courts_analysis;
create table us_case_report_rachelle
(
    id         bigint auto_increment primary key,
    court_id  bigint(20),
    case_id          varchar(255)                         null,
    case_name         text                         null,
    activity_id bigint(20),
    link_pdf     varchar(500)                         null,
    top5_matches   text null,

    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `case_id` (`case_id`),
    INDEX `court_id` (`court_id`)
)
    collate = utf8mb4_unicode_520_ci;




use us_courts_analysis;
INSERT INTO us_case_types_rachelle_categorized (court_id, case_type, count, priority, general_category,midlevel_category, specific_category, additional_category )
SELECT court_id, case_type, count, type_r.priority, type_r.general_category, type_r.midlevel_category, type_r.specific_category, type_r.additional_category from
    (select court_id, case_type, count(*) count from us_courts.us_case_info group by court_id, case_type) as type_counts
     join us_courts_analysis.us_case_types_rachelle as type_r on type_counts.case_type = type_r.values




SELECT DISTINCT general_category from us_case_types_rachelle_categorized UNION
SELECT DISTINCT midlevel_category from us_case_types_rachelle_categorized UNION
SELECT DISTINCT specific_category from us_case_types_rachelle_categorized UNION
SELECT DISTINCT additional_category from us_case_types_rachelle_categorized



SELECT r.court_id, t.court_name, r.case_id, c.case_name, r.top5_matches, count(*), a.link_to_pdf as example FROM us_case_report_rachelle r
    join us_courts.us_case_info c on c.case_id = r.case_id
    join us_courts.us_courts_table t on t.court_id = r.court_id
    join us_courts.us_case_report_aws a on a.activity_id = r.activity_id
group by top5_matches order by r.court_id


SELECT pdf.court_id, uct.court_name, pdf.case_id, uca.activity_type, uca.activity_decs, Concat('https://court-cases-activities.s3.amazonaws.com/',pdf.file)
    from us_case_activities_pdf pdf
    join us_courts_table uct on pdf.court_id = uct.court_id
    join us_case_activities uca on pdf.activity_id = uca.id

