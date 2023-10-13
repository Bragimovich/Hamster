create table us_courts_analysis.analysis_litigation_courts_activities__keywords
(
    id              bigint auto_increment primary key,
    court_id        int,
    case_id         varchar(255)                         null,
    keyword         varchar(255)                         null,
    activity_id     bigint(20),

    source_spreadsheet varchar(255) default 'https://docs.google.com/spreadsheets/d/1452dIfwovGup7MBs6X3EZOU_3mWXnY7tLyGnLZFPUx8/edit#gid=1487576882',
    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `activity_id` (`activity_id`),
    INDEX `keyword` (`keyword`),
    constraint keyword_activity
        unique (keyword, activity_id)
)
    collate = utf8mb4_unicode_520_ci;


create table us_courts_analysis.litigation_case_activity_desc__matching_keyword
(
    id              bigint auto_increment primary key,
    court_id            int,
    court_name          varchar(255),
    case_id             varchar(255),
    case_name           varchar(255),
    keyword             varchar(255)                         null,
    category_name       varchar(255)                         null,
    activity_desc       varchar(1023)                         null,
    activity_id      bigint(20),

    source_spreadsheet varchar(255) default 'https://docs.google.com/spreadsheets/d/1452dIfwovGup7MBs6X3EZOU_3mWXnY7tLyGnLZFPUx8/edit#gid=1487576882',
    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `court_id` (`court_id`),
    INDEX `case_id` (`case_id`),
    INDEX `keyword` (`keyword`),
    INDEX `activity_id` (`activity_id`),
    constraint keyword_text
        unique (keyword, activity_id)
)
    collate = utf8mb4_unicode_520_ci;