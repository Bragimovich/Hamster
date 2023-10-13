create table us_courts_analysis.litigation_keyword_to_case
(
    id                  bigint auto_increment
        primary key,
    keyword             varchar(255)                                                                                                                   null,
    court_id            int                                                                                                                         null,
    case_id            varchar(255)                                                                                                                         null,
    type                varchar(155),
    pdf_link            varchar(255)                                                                                                                   null,


    created_at          datetime     default CURRENT_TIMESTAMP                                                                                         null,
    INDEX keyword (keyword),
    INDEX case_id (case_id),
    INDEX court_id (court_id),
    constraint set_categories
        unique (keyword, court_id, case_id, type)
)
    collate = utf8mb4_unicode_520_ci
    COMMENT = 'The table for categorization cases with all type. Made by Maxim G. Date: 2022-08-12'
;



INSERT IGNORE INTO us_courts_analysis.litigation_keyword_to_case (keyword, court_id, case_id, type, pdf_link)
SELECT kt.keyword, rt.court_id, rt.case_id, 'pdf', aws_link  FROM us_courts_analysis.us_case_pdfs_keyword_to_text kt
join us_courts_analysis.us_case_report_text rt on rt.id = kt.case_report_text_id;

INSERT IGNORE INTO us_courts_analysis.litigation_keyword_to_case (keyword, court_id, case_id, type, pdf_link)
SELECT keyword, court_id, case_id, 'activity', null   FROM us_courts_analysis.analysis_litigation_courts_activities__keywords

INSERT IGNORE INTO us_courts_analysis.litigation_keyword_to_case (keyword, court_id, case_id, type, pdf_link)
SELECT keyword, court_id, case_id, 'info_description', null   FROM us_courts_analysis.us_case_keyword_to_description

