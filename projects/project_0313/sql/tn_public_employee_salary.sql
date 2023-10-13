CREATE TABLE `tn_public_employee_salary`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `agency`                    VARCHAR (255),
  `first_name`                VARCHAR (255),
  `last_name`                 VARCHAR (255),
  `full_name`                 VARCHAR (255),
  `job_title`                 VARCHAR (255),
  `full_time_or_part_time`    VARCHAR (255),
  `compensation_rate`         DECIMAL(65,2),
  `compensation_rate_period`  VARCHAR (255),
  `created_at`                DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_dev_name`           VARCHAR(255)      DEFAULT 'Adeel',
  `data_source_url`           VARCHAR(255)      DEFAULT 'https://apps.tn.gov/salary-app/search.html',
  `source_updated_date`       DATE, 
  `scrape_frequency`          VARCHAR(255) DEFAULT 'Yearly',
  `md5_hash`                  varchar(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', agency, first_name, last_name, full_name, job_title, full_time_or_part_time, CAST(compensation_rate as CHAR), compensation_rate_period, source_updated_date))) STORED,
  `run_id`                    INT,
  UNIQUE KEY `md5` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
