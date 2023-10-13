create table us_courts_analysis.us_case_keyword_to_description
(
    id                  bigint auto_increment primary key,
    keyword             varchar(255),
    case_id         varchar(255),
    type_categorization         varchar(255),
    source_spreadsheet  varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null,

    constraint set_categories
  unique (keyword, case_id, type_categorization)
)
collate = utf8mb4_unicode_520_ci;

