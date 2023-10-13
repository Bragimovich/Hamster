create table us_courts_analysis.litigation_case_type__IRL_keyword_to_text
(
    id                  bigint auto_increment
        primary key,
    keyword           varchar(255),
    report_text_id    bigint,

    source_spreadsheet  varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null,
    constraint set_categories
        unique (keyword, report_text_id)
)
    collate = utf8mb4_unicode_520_ci;

