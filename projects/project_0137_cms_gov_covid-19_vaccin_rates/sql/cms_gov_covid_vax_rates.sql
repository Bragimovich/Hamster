CREATE TABLE `cms_gov_covid_vax_rates`
(
    `id`                             BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `state`                          VARCHAR(255),
    `pct_vaxed_residents`            DECIMAL(3, 1),
    `pct_vaxed_healthcare_personnel` DECIMAL(3, 1),
    `vax_data_updated_on`            DATE,
    `data_source_url`                VARCHAR(255)       DEFAULT 'https://data.cms.gov/provider-data/dataset/avax-cv19',
    `created_by`                     VARCHAR(255)       DEFAULT 'Yunus Ganiyev',
    `created_at`                     DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `pct` (`pct_vaxed_residents`, `pct_vaxed_healthcare_personnel`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
