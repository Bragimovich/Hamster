 CREATE TABLE `nj_state_employees_salaries` 
 (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `record_type` varchar(150) DEFAULT NULL,
  `ytd_earnings` varchar(150) DEFAULT NULL,
  `cash_in_lieu_maintenance` varchar(150) DEFAULT NULL,
  `lump_sum_pay` varchar(150) DEFAULT NULL,
  `retroactive_pay` varchar(150) DEFAULT NULL,
  `clothing_uniform_payments` varchar(150) DEFAULT NULL,
  `overtime_payments` varchar(150) DEFAULT NULL,
  `legislator_or_back_pay` varchar(150) DEFAULT NULL,
  `one_time_payments` varchar(150) DEFAULT NULL,
  `supplemental_pay` varchar(150) DEFAULT NULL,
  `regular_pay` varchar(150) DEFAULT NULL,
  `paid_section_desc` varchar(150) DEFAULT NULL,
  `paid_department_agency_desc` varchar(150) DEFAULT NULL,
  `master_ytd_earnings` varchar(150) DEFAULT NULL,
  `master_ytd_all_other_payments` varchar(150) DEFAULT NULL,
  `master_ytd_overtime_payments` varchar(150) DEFAULT NULL,
  `master_ytd_regular_pay` varchar(150) DEFAULT NULL,
  `compensation_method` varchar(150) DEFAULT NULL,
  `employee_relations_group` varchar(150) DEFAULT NULL,
  `master_title_desc` varchar(150) DEFAULT NULL,
  `master_section_desc` varchar(150) DEFAULT NULL,
  `master_department_agency_desc` varchar(150) DEFAULT NULL,
  `salary_hourly_rate` varchar(150) DEFAULT NULL,
  `original_employment_dte` varchar(150) DEFAULT NULL,
  `full_name` varchar(150) DEFAULT NULL,
  `middle_initial` varchar(150) DEFAULT NULL,
  `first_name` varchar(150) DEFAULT NULL,
  `last_name` varchar(150) DEFAULT NULL,
  `payroll_id` varchar(150) DEFAULT NULL,
  `as_of_date` varchar(150) DEFAULT NULL,
  `calendar_quarter` varchar(150) DEFAULT NULL,
  `calendar_year` varchar(150) DEFAULT NULL,
  `data_source_url` varchar(100) NOT NULL DEFAULT 'https://data.nj.gov/Government-Finance/YourMoney-Agency-Payroll/iqwc-r2w7/data',
  `scrape_frequency` varchar(25) NOT NULL DEFAULT 'yearly',
  `scrape_dev_name` varchar(25) NOT NULL DEFAULT 'Aqeel',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash` varchar(100) GENERATED ALWAYS AS (md5(concat_ws('',calendar_year,calendar_quarter,as_of_date,payroll_id,full_name,original_employment_dte,salary_hourly_rate,master_department_agency_desc,master_section_desc,master_title_desc,employee_relations_group,compensation_method,master_ytd_regular_pay,master_ytd_overtime_payments,master_ytd_all_other_payments,master_ytd_earnings,paid_department_agency_desc,paid_section_desc,record_type))) STORED,
  UNIQUE KEY `md5` (`md5_hash`)
  PRIMARY KEY (`id`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
