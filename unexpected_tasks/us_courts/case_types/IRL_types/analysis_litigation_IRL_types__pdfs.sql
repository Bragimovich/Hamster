create table us_courts_analysis.analysis_litigation_IRL_types__pdfs
(
    id                 bigint auto_increment
        primary key,
    court_id           bigint                                                                                                                      null,
    case_id            varchar(255)                                                                                                                null,
    case_name          text                                                                                                                        null,
    activity_id        bigint                                                                                                                      null,
    link_pdf           varchar(500)                                                                                                                null,
    top5_matches       text                                                                                                                        null,
    created_by         varchar(255) default 'Maxim G'                                                                                              null,
    created_at         datetime     default CURRENT_TIMESTAMP                                                                                      null,
    updated_at         timestamp    default CURRENT_TIMESTAMP                                                                                      not null on update CURRENT_TIMESTAMP,
    source_spreadsheet varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null,
    INDEX `case_id` (`case_id`),
    INDEX `court_id` (`court_id`)
)
    collate = utf8mb4_unicode_520_ci;

create index uniq_text
    on us_courts_analysis.analysis_litigation_rachelle_types__pdfs (court_id, case_id, activity_id);

