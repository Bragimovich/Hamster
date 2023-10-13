CREATE TABLE `ks_public_employee_salaries`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                    int,
  `year`                      int(11),
  `first_name`                varchar(255),
  `middle_name`               varchar(255),
  `last_name`                 varchar(255),
  `full_name`                 varchar(255),
  `agency`                    varchar(255),
  `position`                  varchar(255),
  `salary`                    int,
  `scrape_dev_name`           VARCHAR(255) DEFAULT 'Adeel',
  `data_source_url`           VARCHAR(255) DEFAULT 'http://www.kansasopengov.org/kog/databank#report_id=4',
  `scrape_frequency`          VARCHAR(255) DEFAULT 'yearly',
  `scrape_status`             VARCHAR(255) DEFAULT 'Live',
  `pl_gather_task_id`         bigint(20),
  `last_scrape_date`          date,
  `next_scrape_date`          date,
  `expected_scrape_frequency` VARCHAR(255) DEFAULT 'yearly',
  `dataset_name_prefix`       varchar(255) DEFAULT 'ks_public_employee_salaries',
  `created_at`                DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`                  varchar(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', year, full_name, agency, position, salary))) STORED,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
