CREATE TABLE `RPC_refugee_arrivals_by_admission_category_data`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  `report_start_date`     VARCHAR(255),
  `report_end_date`       VARCHAR(255),
  `admission_category`    VARCHAR(255),
  `admission_subcategory` VARCHAR(255),
  `month`                 VARCHAR(255),
  `refugee_amount`        VARCHAR(255),
  `scrape_frequency`      VARCHAR(255)       DEFAULT 'Monthly',
  `data_source_url`       VARCHAR(255)       DEFAULT 'https://www.wrapsnet.org/admissions-and-arrivals/',
  `created_by`            VARCHAR(255)       DEFAULT 'Art Jarocki',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN            DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
