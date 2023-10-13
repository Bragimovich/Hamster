create table us_courts_analysis.analysis_litigation_IRL_types__courthouses
(
    id                  bigint auto_increment
        primary key,
    court_id            int                                                                                                                         null,
    case_type           varchar(1023)                                                                                                               null,
    priority            varchar(255)                                                                                                                null,
    count               bigint                                                                                                                      null,
    general_category    varchar(255)                                                                                                                null,
    count_general       bigint                                                                                                                      null,
    midlevel_category   varchar(255)                                                                                                                null,
    count_midlevel      bigint                                                                                                                      null,
    specific_category   varchar(255)                                                                                                                null,
    count_specific      bigint                                                                                                                      null,
    additional_category varchar(255)                                                                                                                null,
    count_additional    bigint                                                                                                                      null,
    source_spreadsheet  varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null
)
    collate = utf8mb4_unicode_520_ci;

