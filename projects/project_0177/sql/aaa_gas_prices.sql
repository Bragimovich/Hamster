create table aaa_gas_prices_daily
(
    id                          INT NOT NULL AUTO_INCREMENT,
    report_date                 DATE,
    state                       VARCHAR(255),
    current_regular_price       DECIMAL(6, 3),
    current_mid_grade_price     DECIMAL(6, 3),
    current_premium_price       DECIMAL(6, 3),
    current_diesel_price        DECIMAL(6, 3),
    current_e85_price           DECIMAL(6, 3),
    yesterday_regular_price     DECIMAL(6, 3),
    yesterday_mid_grade_price   DECIMAL(6, 3),
    yesterday_premium_price     DECIMAL(6, 3),
    yesterday_diesel_price      DECIMAL(6, 3),
    yesterday_e85_price         DECIMAL(6, 3),
    week_ago_regular_price      DECIMAL(6, 3),
    week_ago_mid_grade_price    DECIMAL(6, 3),
    week_ago_premium_price      DECIMAL(6, 3),
    week_ago_diesel_price       DECIMAL(6, 3),
    week_ago_e85_price          DECIMAL(6, 3),
    month_ago_regular_price     DECIMAL(6, 3),
    month_ago_mid_grade_price   DECIMAL(6, 3),
    month_ago_premium_price     DECIMAL(6, 3),
    month_ago_diesel_price      DECIMAL(6, 3),
    month_ago_e85_price         DECIMAL(6, 3),
    year_ago_regular_price      DECIMAL(6, 3),
    year_ago_mid_grade_price    DECIMAL(6, 3),
    year_ago_premium_price      DECIMAL(6, 3),
    year_ago_diesel_price       DECIMAL(6, 3),
    year_ago_e85_price          DECIMAL(6, 3),
    data_source_url             VARCHAR(255)       DEFAULT 'https://gasprices.aaa.com/?state=US',
    created_by                  VARCHAR(255)       DEFAULT 'Eldar Mustafaev',
    PRIMARY KEY (id)


)
    DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci;