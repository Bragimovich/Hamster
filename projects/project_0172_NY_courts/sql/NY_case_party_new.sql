create table us_court_cases.NY_case_party_new
(
    id                        bigint auto_increment
        primary key,

    case_id               varchar(70)                           not null,
    court_id                  int                                   null,

    party_name                varchar(1024)                         null,
    party_type                varchar(80)                           null,
    party_address             varchar(255)                          null,
    party_city                varchar(255)                          null,
    party_state               varchar(255)                          null,
    party_zip                 varchar(255)                          null,
    law_firm                  varchar(255)                          null,
    lawyer_additional_date      varchar(255)            null,

    party_description         text                         null,
    is_lawyer                 tinyint(1)  default 0                 null,

    data_source_url           varchar(200)                          not null,
    created_by           varchar(255)                          null,
    created_at                timestamp   default CURRENT_TIMESTAMP not null,
    updated_at                timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    scrape_frequency          varchar(255)                        null,


    run_id                    BIGINT(20),
    touched_run_id            BIGINT(20),
    deleted                   TINYINT(1) default 0,

    md5_hash                  varchar(50)                           null,
    INDEX `case_number` (`case_id`),
    INDEX `md5_hash` (`md5_hash`)
)
    collate = utf8mb4_unicode_520_ci;



INSERT INTO NY_case_party_new (court_id, case_id,
                               party_name, law_firm, party_type
                               data_source_url, created_by,scrape_frequency, md5_hash)
SELECT court_id, case_id, defendant_lawyer, defendant_lawyer_firm, 'defendant',
    data_source_url, scrape_dev_name, scrape_frequency, md5_hash from NY_case_lawyers WHERE defendant_lawyer!=''


INSERT INTO NY_case_party_new (court_id, case_id,
                               party_name, law_firm, party_type,
                               data_source_url, created_by,scrape_frequency, md5_hash)
SELECT court_id, case_number, plaintiff_lawyer, plaintiff_lawyer_firm, 'plaintiff',
       data_source_url, scrape_dev_name, scrape_frequency, md5_hash from NY_case_lawyer WHERE plaintiff_lawyer!=''