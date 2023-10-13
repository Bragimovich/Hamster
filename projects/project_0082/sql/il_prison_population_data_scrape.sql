create table hle_data.il_prison_population_data_scrape
(
    id                                                 int auto_increment   primary key,
    data_source_url                                    varchar(255)                        null,
    Idoc                                               varchar(255)                        null,
    name                                               varchar(255)                        null,
    date_of_birth                                      date                                null,
    sex                                                varchar(255)                        null,
    race                                               varchar(255)                        null,
    veteran_status                                     varchar(255)                        null,
    current_admission_date                             date                                null,
    admission_type                                     varchar(255)                        null,
    parent_institution                                 varchar(255)                        null,
    projected_mandatory_supervised_release_date        date                                null,
    projected_discharged_date                          date                                null,
    custody_date                                       date                                null,
    sentenced_date                                     date                                null,
    crime_class                                        varchar(255)                        null,
    holding_offense                                    varchar(255)                        null,
    holding_offense_category                           varchar(255)                        null,
    holding_offense_type                               varchar(255)                        null,
    sentence_years                                     varchar(255)                        null,
    sentence_month                                     int                                 null,
    truth_in_sentencing                                varchar(255)                        null,
    sentecning_county                                  varchar(255)                        null,
    period                                             date                                null,
    created_by                                         varchar(255)                        null,
    created_date                                       datetime                            null,
    updated_at                                         timestamp default CURRENT_TIMESTAMP not null,
    broken_date_of_birth                               varchar(255)                        null,
    broken_current_admission_date                      varchar(255)                        null,
    broken_projected_mandatory_supervised_release_date varchar(255)                        null,
    broken_projected_discharged_date                   varchar(255)                        null,
    broken_custody_date                                varchar(255)                        null,
    broken_sentenced_date                              varchar(255)                        null,
    age_on_begin_of_report_month                       decimal(6, 3)                       null,
    age_on_begin_of_report_quarter                     decimal(6, 3)                       null
);

create index parent_institution_index
    on hle_data.il_prison_population_data_scrape (parent_institution);

create index period_projected_mandatory_supervised_release_date_index
    on hle_data.il_prison_population_data_scrape (period, projected_mandatory_supervised_release_date);

