use us_courts_analysis;
create table us_case_courthouse_counts
(
    id                    bigint auto_increment
        primary key,
    court_id              bigint(20),
    total_cases               bigint(20),
    last_scrape_date             DATETIME,
    total_new_cases_from_last_scrape             bigint(20),
    scheduled_next_scrape_date       DATE,
    last_updated       datetime,
    INDEX `court_id` (`court_id`)
);
