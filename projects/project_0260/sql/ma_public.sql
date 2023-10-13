CREATE TABLE `ma_public_employee_salaries`(
  `id` bigint(20) NOT NULL AUTO_INCREMENT  PRIMARY KEY,
  `file_name` varchar(255),
  `year` integer,
  `last_name` varchar(255),
  `first_name` varchar(255),
  `department_division` varchar(255),
  `position_title` varchar(255),
  `position_type` varchar(255),
  `service_end_date` date,
  `pay_total_actual` decimal(10,3),
  `pay_base_actual` decimal(10,3),
  `pay_buyout_actual` decimal(10,3),
  `pay_overtime_actual` decimal(10,3),
  `pay_other_actual` decimal(10,3),
  `annual_rate` decimal(10,3),
  `pay_year_to_date` decimal(10,3),
  `department_location_zip_code` varchar(255),
  `contract`   varchar(255),
  `bargaining_group_no` varchar(255),
  `bargaining_group_title` varchar(255),
  `tans_no` varchar(255),
  `dept_code` varchar(255),
  `data_source_url` varchar(255),
  `md5_hash` varchar(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', file_name,year, last_name, first_name, department_division,  position_title, position_type, service_end_date, pay_total_actual, pay_base_actual, pay_buyout_actual, pay_overtime_actual, pay_other_actual, annual_rate, pay_year_to_date, department_location_zip_code, contract, bargaining_group_no, bargaining_group_title, tans_no, dept_code,data_source_url))) STORED,
  `run_id`    int,
  `last_scrape_date` Date,
  `next_scrape_date` Date,
  `expected_scrape_frequency` varchar(255)  DEFAULT 'Monthly'
  `scrape_frequency`   varchar(255)         DEFAULT 'Monthly'
  `dataset_name_prefix`       varchar(255)  DEFAULT 'ma_public_employee_salaries',
  `scrape_status`             varchar(255)  DEFAULT 'Live'
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
