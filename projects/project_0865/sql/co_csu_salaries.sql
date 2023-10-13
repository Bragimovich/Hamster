CREATE TABLE `co_csu_salaries`(
  `id` bigint(20) NOT NULL AUTO_INCREMENT primary key,
  `unit_name`  varchar(255),
  `department`       varchar(255),
  `last_name`     varchar(255),
  `first_initial`     varchar(255),
  `job_title`   varchar(255),
  `contract`   varchar(255),
  `appointment_type`         varchar(255),
  `full_time_equivalent`     decimal(10,2),
  `annual_salary`       decimal(10, 2),
  `extract_date`       varchar(255),
  `data_source_url` varchar(255) default "https://www.ir.colostate.edu/wp-content/uploads/sites/12/2023/06/CSU_Compensation_Report.xlsx",
  `scrape_dev_name` varchar(255)  default "Tauseeq",
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`           int,
  `deleted`          boolean default '0',
  `touched_run_id`   int,
  `md5_hash`         varchar(255) UNIQUE KEY,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX deleted_idx (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Tauseeq Tufail, Task #0865';
