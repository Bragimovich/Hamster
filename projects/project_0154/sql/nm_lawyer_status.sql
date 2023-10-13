CREATE TABLE lawyer_status.nm_bar_sbnm_org
(
    id                          int auto_increment primary key,
    bar_number                  varchar(255)    null,
    name                        varchar(255)    null,
    first_name                  varchar(255)    null,
    last_name                   varchar(255)    null,
    middle_name                 varchar(255)    null,
    date_admitted               date            null,
    registration_status         varchar(255)    null,
    sections                    text            null,
    type                        varchar(255)    null,
    phone                       varchar(255)    null,
    email                       varchar(255)    null,
    fax                         varchar(255)    null,
    law_firm_name               varchar(255)    null,
    law_firm_address            varchar(255)    null,
    law_firm_zip                varchar(255)    null,
    law_firm_city               varchar(255)    null,
    law_firm_state              varchar(255)    null,
    law_firm_county             varchar(255)    null,
    name_prefix                 varchar(255)    null,
    university                  varchar(255)    null,
    professional_affiliation    text            null,
    bio                         longtext        null,
    website                     varchar(255)    null,
    linkedin                    varchar(255)    null,
    facebook                    varchar(255)    null,
    twitter                     varchar(255)    null,
    law_firm_website            varchar(255)    null,
    other_jurisdictions         text            null,
    judicial_district           varchar(255)    null,
    disciplinary_actions        text            null,
    private_practice            varchar(255)    null,
    insurance                   varchar(255)    null,
    courts_of_admittance        varchar(255)    null,
    scrape_frequency            varchar(255)    default 'weekly',
    data_source_url             varchar(255)    null,
    run_id                      bigint          null,
    touched_run_id              bigint          null,
    deleted                     tinyint(1)      default 0 null,
    md5_hash                    varchar(255)    null,
    created_by                  varchar(255)    DEFAULT 'Alim L.',
    created_at                  DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;