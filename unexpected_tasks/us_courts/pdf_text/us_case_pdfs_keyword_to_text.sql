create table us_courts_analysis.us_case_pdfs_keyword_to_text
(
    id                 bigint auto_increment
        primary key,
    keyword            varchar(255)                                                                                                                   null,
    case_report_text_id     bigint                                                                                                                         null,
    count              int                                                                                                                            null,
    source_spreadsheet varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null,
    pdf_link           varchar(255)                                                                                                                   null,
    constraint set_categories
        unique (keyword, case_report_text_id)
)
    collate = utf8mb4_unicode_520_ci;

