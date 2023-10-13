use lawyer_status;
create table nevada
(
    id                      bigint(20) auto_increment
        primary key,

    bar_number              varchar(15)                                    null,
    name                    varchar(255)                               null,
    first_name              varchar(255)                               null,
    last_name               varchar(255)                               null,
    middle_name             varchar(255)                               null,

    link                    varchar(511)                               null,
    law_firm_name           varchar(1023)                                null,
    law_firm_address        varchar(2045)                                null,
    law_firm_zip            varchar(255)                               null,
    law_firm_city           varchar(255)                               null,

    law_firm_state          varchar(15)                                 null,
    phone                   varchar(255)                               null,
    email                   varchar(255)                               null,
    date_admitted           datetime                                 null,
    sections                varchar(1023)                               null,
    registration_status     varchar(255)                               null,



    data_source_url         varchar(255) default 'https://nvbar.org/for-the-public/find-a-lawyer/'                null,
    created_by              varchar(30)  default 'Maxim G' null,
    created_at              datetime     default CURRENT_TIMESTAMP   null,
    updated_at              timestamp    default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
    run_id                  bigint                                   null,
    touched_run_id          bigint                                   null,
    deleted                 tinyint(1)         default 0               null,
    md5_hash                varchar(255)                               null,
    scrape_frequency        varchar(100)    default 'daily'            null,
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`),
    INDEX `bar_number` (`bar_number`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

