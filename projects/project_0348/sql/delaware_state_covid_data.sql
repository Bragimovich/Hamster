CREATE TABLE `delaware_state_covid_data`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `location`       VARCHAR(255),
  `county`       VARCHAR(255),
  `statistic`       VARCHAR(255),
  `value`       int,
  `year`       int,
  `month`       int,
  `day`         int,
  `date_used`   VARCHAR(255),
  `unit`         VARCHAR(255),
  `age_adjusted`  VARCHAR(255),
  `data_source_url` VARCHAR(255) DEFAULT "https://myhealthycommunity.dhss.delaware.gov/locations/state",
  `created_by`      VARCHAR(255)       DEFAULT 'Adeel',
  `scrape_frequency` VARCHAR(50)       DEFAULT 'weekly',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `unique_data` (`md5_hash` , `value`),
  INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
