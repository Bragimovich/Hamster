
create table us_courts_analysis.litigation_case_type__IRL_keywords
(
    id              bigint auto_increment primary key,
    keyword         varchar(255)                         null,
    category_id     bigint(20),
    category_name   varchar(255)                         null,

    source_spreadsheet varchar(255) default 'https://docs.google.com/spreadsheets/d/1452dIfwovGup7MBs6X3EZOU_3mWXnY7tLyGnLZFPUx8/edit#gid=1487576882',
    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,

    constraint keyword_category
        unique (keyword, category_id)
)
    collate = utf8mb4_unicode_520_ci;



create table us_courts_analysis.litigation_case_type__matching_keyword
(
    id              bigint auto_increment primary key,
    сourt_id            int,
    court_name          varchar(255),
    case_id             varchar(255),
    case_name           varchar(255),
    keyword             varchar(255)                         null,
    category_name       varchar(255)                         null,
    report_text_id      bigint(20),
    pdf_link            varchar(255)                         null,

    source_spreadsheet varchar(255) default 'https://docs.google.com/spreadsheets/d/1452dIfwovGup7MBs6X3EZOU_3mWXnY7tLyGnLZFPUx8/edit#gid=1487576882',
    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `сourt_id` (`сourt_id`),
    INDEX `case_id` (`case_id`),
    INDEX `keyword` (`keyword`),
    INDEX `report_text_id` (`report_text_id`),
    constraint keyword_text
        unique (keyword, report_text_id)
)
    collate = utf8mb4_unicode_520_ci;



UPDATE us_courts_analysis.litigation_case_type__matching_keyword mk
join us_courts.us_courts_table court on court.court_id = mk.court_id
SET mk.court_name = court.court_name

UPDATE us_courts_analysis.litigation_case_type__matching_keyword mk
    join us_courts.us_case_info info on info.case_id = mk.case_id
SET mk.case_name = info.case_name