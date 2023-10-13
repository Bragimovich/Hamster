CREATE TABLE `ut_public_employee_salaries`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                    int,
  `fiscal_year`               varchar(255),
  `entity`                    varchar(255),
  `employee_name`             varchar(255),
  `title`                     varchar(255),
  `wages`                     decimal(12,2),
  `benefits`                  decimal(12,2),
  `total`                     decimal(12,2),
  `scrape_dev_name`           VARCHAR(255) DEFAULT 'Adeel',
  `last_scrape_date`          DATE,
  `next_scrape_date`          Date,
  `scrape_frequency`          VARCHAR(255) DEFAULT 'Yearly',
  `scrape_status`             VARCHAR(255) DEFAULT 'Live',
  `expected_scrape_frequency` VARCHAR(255) DEFAULT 'Yearly',
  `dataset_name_prefix`       varchar(255) DEFAULT 'ut_public_employee_salaries',
  `data_source_url`           VARCHAR(255) DEFAULT 'https://transparent.utah.gov/empdet.php',
  `created_at`                DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`                  varchar(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', fiscal_year, entity,employee_name, title, CAST(wages as CHAR), CAST(benefits as CHAR), CAST(total as CHAR)))) STORED,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
