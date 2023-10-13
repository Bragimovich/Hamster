CREATE TABLE `cook_county_influenza_weekly_report`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          int,
  `year`            VARCHAR(255),
  `week`            VARCHAR(255),
  `link`            VARCHAR (255),
  `proportion_of_emergency_deparatment_visits`    NUMERIC(65,4),
  `proportion_of_outpatient_provider_visits`      NUMERIC(65,4),
  `proportion_of_deaths_associated_with_flu`      NUMERIC(65,4),
  `num_influenza_total`                           INT (255),
  `pct_tested_positive`                           NUMERIC(65,4),
  `num_influenza_a_unknown_subtype`               INT (255),
  `num_influenza_a_h1n1`                          INT (255),
  `num_influenza_a_h3n2`                          INT (255),
  `num_influenza_b`                               INT (255),
  `num_flu_associated_icu`                        INT (255),
  `num_pediatric_deaths_since_week35`            INT (255),
  `num_clusters_il_schools_since_week35`         INT (255),
  `num_outbreaks_in_long_term_care_since_week35` INT (255),
  `scrape_dev_name`                               VARCHAR(255) DEFAULT 'Adeel',
  `data_source_url`                               VARCHAR(255) DEFAULT 'https://cookcountypublichealth.org/epidemiology-data-reports/communicable-disease-data-reports/',
  `scrape_frequency`                              VARCHAR(255) DEFAULT 'Weekly',
  `deleted`                                       int DEFAULT 0,
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `link_idx` (`link`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

