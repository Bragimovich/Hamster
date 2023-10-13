CREATE TABLE `fda_inspections`
(
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `run_id`               BIGINT(20),
  `fei_number`           Varchar(255),
  `legal_name`           Varchar(255),
  `city`                 Varchar(255),
  `state`                Varchar(255),
  `zip_code`             Varchar(255),
  `country`              Varchar(255),
  `district`             Varchar(255),
  `year`                 Varchar(255),
  `inspection_id`        Int,
  `posted_citations`     Varchar(255),
  `inspection_end_date`  Date,
  `classification`       Varchar(255),
  `project_area`         Varchar(255),
  `product_type`         Varchar(255),
  `firm_profile`         Varchar(255),
  `md5_hash`             Varchar(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', fei_number, legal_name, city, state, zip_code, country, year, CAST(inspection_id as CHAR), posted_citations, CAST(inspection_end_date as CHAR), classification, project_area, product_type, firm_profile))) STORED,
  `data_source_url`      Varchar(255) DEFAULT 'https://datadashboard.fda.gov/ora/cd/inspections.htm',
  `deleted`              tinyint(1)   DEFAULT 0,
  `touch_run_id`         BIGINT(20),
  `scrape_frequency`     Varchar(255)       DEFAULT 'Monthly',
  `scrape_dev_name`      VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`)
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
COMMENT = 'Created by Adeel Anwar, Task #432';
