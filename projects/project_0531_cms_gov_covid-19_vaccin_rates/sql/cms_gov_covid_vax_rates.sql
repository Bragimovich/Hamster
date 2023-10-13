CREATE TABLE `cms_gov_covid_vax_rates`
(
    `id`                                                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `state`                                                     VARCHAR(255),
    `pct_of_residents_who_completed_primary_vaccination_series` DECIMAL(4, 1),
    `pct_of_staff_who_completed_primary_vaccination_series`     DECIMAL(4, 1),
    `pct_of_residents_who_are_up_to_date_on_their_vaccines`     DECIMAL(4, 1),
    `pct_of_staff_who_are_up_to_date_on_their_vaccines`         DECIMAL(4, 1),
    `date_vax_data_last_updated`                                       DATE,
    `data_source_url`                                           VARCHAR(255)       DEFAULT 'https://data.cms.gov/provider-data/dataset/avax-cv19',
    `created_by`                                                VARCHAR(255)       DEFAULT 'Yunus Ganiyev',
    `created_at`                                                DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                                                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `pct` (`pct_of_residents_who_completed_primary_vaccination_series`, `pct_of_staff_who_completed_primary_vaccination_series`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
