CREATE TABLE kansas_campaign_finance_expenditures (
    id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    candidate_name varchar(255) DEFAULT NULL,
    recipient     varchar(255) DEFAULT NULL,
    address        varchar(255) DEFAULT NULL,
    address_2      varchar(255) DEFAULT NULL,
    city           varchar(255) DEFAULT NULL,
    state          varchar(255) DEFAULT NULL,
    zip            varchar(20) DEFAULT NULL,
    date           date NULL,
    expenditure_description varchar(255) DEFAULT NULL,
    amount                    decimal(10, 2) default 0.00              null,
    period_start_date                date                                     null,
    period_end_date                  date                                     null,

    scrape_dev_name varchar(255) DEFAULT 'dsuschinsky',
    created_at datetime DEFAULT NULL,
    updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_scrape_date date DEFAULT NULL,
    next_scrape_date date DEFAULT NULL,
    expected_scrape_frequency varchar(255) DEFAULT NULL,
    scrape_status varchar(255) DEFAULT NULL,
    run_id int(11)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
