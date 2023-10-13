create table us_courts_analysis.litigation_case_to_unique_category
(
    id                 bigint auto_increment
        primary key,
    court_id           int,
    case_id            varchar(255),
    unique_category_id bigint,
    pdf_link           varchar(255),
    created_at          datetime     default CURRENT_TIMESTAMP null,
    source_spreadsheet varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null,
    INDEX case_id (case_id),
    INDEX court_id (court_id),
    INDEX unique_category_id (unique_category_id),
    constraint unique_row
        unique (court_id, case_id, unique_category_id)
)
    collate = utf8mb4_unicode_520_ci
    COMMENT = 'Link cases to unique category. Made by Maxim G (2022-08-13)'
;


INSERT IGNORE INTO us_courts_analysis.litigation_case_to_unique_category (court_id, case_id, unique_category_id, pdf_link)
SELECT t.court_id, t.case_id, uc.unique_category_id, uc.pdf_link FROM us_courts_analysis.litigation_case_type__IRL_pdfs_unique_categories uc
join us_courts_analysis.us_case_report_text t on uc.report_text_id=t.id


