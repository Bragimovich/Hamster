-- auto-generated definition
create table il_parole_population_date_scrape_temp
(
    id                                int auto_increment primary key,
    data_source_url                   varchar(255)                        null,
    idoc                              varchar(255)                        null,
    name                              varchar(255)                        null,
    date_of_birth                     date                                null,
    sex                               varchar(255)                        null,
    race                              varchar(255)                        null,
    veteran_status                    varchar(255)                        null,
    current_admission_date            date                                null,
    admission_type                    varchar(255)                        null,
    parent_institution                varchar(255)                        null,
    mandatory_supervised_release_date date                                null,
    projected_discharge_date          date                                null,
    custody_date                      date                                null,
    sentenced_date                    date                                null,
    crime_class                       varchar(255)                        null,
    holding_offense                   varchar(255)                        null,
    sentence_years                    varchar(255)                        null,
    sentence_month                    int                                 null,
    truth_in_sentencing               varchar(255)                        null,
    sentencing_county                 varchar(255)                        null,
    county_of_residence               varchar(255)                        null,
    residence_zip_code                int                                 null,
    period                            date                                null,
    created_by                        varchar(255)                        null,
    created_at                        datetime                            null,
    updated_at                        timestamp default CURRENT_TIMESTAMP not null,
    city                              varchar(255)                        null,
    county                            varchar(255)                        null,
    state                             varchar(15)                         null,
    pl_prod_county_id                 varchar(1000)                       null,
    pl_prod_city_id                   bigint                              null,
    zip_lat                           double                              null,
    zip_lon                           double                              null
);

create index holding_offense_index
    on il_parole_population_date_scrape_temp (holding_offense);

create index period_idoc_index
    on il_parole_population_date_scrape_temp (period, idoc);