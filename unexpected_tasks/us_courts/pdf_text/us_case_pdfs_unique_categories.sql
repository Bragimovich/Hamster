create table us_courts_analysis.us_case_pdfs_unique_categories
(
    id                 bigint auto_increment
        primary key,
    unique_category_id bigint                                                                                                                         null,
    pdf_link           varchar(255)                                                                                                                   null,
    case_report_text_id     bigint                                                                                                                         null,
    source_spreadsheet varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null,
    court_id           int                                                                                                                            null,
    case_id            varchar(255)                                                                                                                   null,
    constraint unique_row
        unique (unique_category_id, case_report_text_id)
)
    collate = utf8mb4_unicode_520_ci;

create index case_report_text_id
    on us_courts_analysis.us_case_pdfs_unique_categories (case_report_text_id);

