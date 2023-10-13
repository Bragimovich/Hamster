CREATE TABLE `fl_hurricane_insurance__state_data`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`            BIGINT(20),
  `hurricane_id`      INT,
  `business_categ_id` VARCHAR(255),
  `data_categ_id`     INT,
  `business_id`       BIGINT(20),
  `value`             DECIMAL(14,2) DEFAULT NULL,
  `value_unit`        VARCHAR(15),
  `scrape_dev_name`   VARCHAR(255)      DEFAULT 'Adeel',
  `data_source_url`   VARCHAR(255) DEFAULT NULL,
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequency`  VARCHAR(255) DEFAULT 'Yearly',
  `touched_run_id`    BIGINT(20),
  `deleted`           BOOLEAN   DEFAULT 0,
  `md5_hash`          VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
