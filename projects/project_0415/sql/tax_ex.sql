use usa_raw; -- db01
create table usa_raw.us_tax_exempt_organizations__publication_78_EXP
(
    id   int auto_increment   primary key,
    ein               varchar(255) null,
    organization        varchar(255) null,
    city               varchar(255) null,
    state                varchar(255) null,
    country                varchar(255) null,
    classification                varchar(255) null,

    last_date varchar (30) default '2022-April-11',

    scrape_frequency varchar(255)  DEFAULT 'monthly',
    data_source_url  VARCHAR(255) default 'https://www.irs.gov/charities-non-profits/tax-exempt-organization-search-bulk-data-downloads',
    created_by      VARCHAR(255) default 'Khalikov',
    created_at      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    run_id                  bigint                                   null,
    touched_run_id          bigint                                   null,
    deleted                 tinyint(1)         default 0               null,
    md5_hash                varchar(255)                               null

);

create index ein_idx
    on usa_raw.us_tax_exempt_organizations__publication_78_EXP (ein);

create index touched_run_id_idx
    on usa_raw.us_tax_exempt_organizations__publication_78_EXP (touched_run_id);
