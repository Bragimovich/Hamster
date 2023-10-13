create table usa_raw.new_york_city_crime_statistics_yearly_history
(
    id                                                 int auto_increment   primary key,
    run_id          BIGINT(20),
    crime_category                                    varchar(255)                        null,
    year                                               varchar(255)                        null,
    amount_of_crimes                                               varchar(255)                        null,
    scrape_frequency                                    varchar(255)  DEFAULT 'yearly',
    data_source_url  VARCHAR(255) DEFAULT 'https://www1.nyc.gov/site/nypd/stats/crime-statistics/citywide-crime-stats.page',
    created_by      VARCHAR(255)       DEFAULT 'Raza',
    created_at      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
