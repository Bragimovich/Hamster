CREATE TABLE `mn_employee_payroll_data`  
( 
   `id`                             int auto_increment  primary key, 
   `run_id`                         BIGINT(20), 
   `temporary_id`                   BIGINT(20), 
   `record_number`                  INT          DEFAULT NULL, 
   `employee_last_name`             VARCHAR(256) DEFAULT NULL, 
   `employee_first_name`            VARCHAR(256) DEFAULT NULL, 
   `employee_middle_initial`        VARCHAR(256) DEFAULT NULL, 
   `agency_number`                  VARCHAR(256) DEFAULT NULL, 
   `agency_name`                    VARCHAR(256) DEFAULT NULL, 
   `department_number`              VARCHAR(256) DEFAULT NULL, 
   `department_name`                VARCHAR(256) DEFAULT NULL, 
   `branch_code`                    VARCHAR(256) DEFAULT NULL, 
   `branch_name`                    VARCHAR(256) DEFAULT NULL, 
   `job_code`                       INT          DEFAULT NULL, 
   `job_title`                      VARCHAR(256) DEFAULT NULL, 
   `location_number`                VARCHAR(256) DEFAULT NULL, 
   `location_name`                  VARCHAR(256) DEFAULT NULL, 
   `location_county_name`           VARCHAR(256) DEFAULT NULL, 
   `location_postal_code`           INT          DEFAULT NULL, 
   `reg_temp_code`                  VARCHAR(256) DEFAULT NULL, 
   `reg_temp_desc`                  VARCHAR(256) DEFAULT NULL, 
   `classified_code`                VARCHAR(256) DEFAULT NULL, 
   `classified_desc`                VARCHAR(256) DEFAULT NULL, 
   `original_hire_date`             VARCHAR(256) DEFAULT NULL, 
   `last_hire_date`                 VARCHAR(256) DEFAULT NULL, 
   `job_entry_date`                 VARCHAR(256) DEFAULT NULL, 
   `full_part_time_code`            VARCHAR(256) DEFAULT NULL, 
   `full_part_time_desc`            VARCHAR(256) DEFAULT NULL, 
   `salary_plan_grid`               VARCHAR(256) DEFAULT NULL, 
   `salary_grade_range`             INT          DEFAULT NULL, 
   `max_salary_step`                INT          DEFAULT NULL, 
   `compensation_rate`              INT          DEFAULT NULL, 
   `comp_frequency_code`            VARCHAR(256) DEFAULT NULL, 
   `comp_frequency_desc`            VARCHAR(256) DEFAULT NULL, 
   `position_fte`                   INT          DEFAULT NULL, 
   `bargaining_unit_number`         INT          DEFAULT NULL, 
   `bargaining_unit_name`           VARCHAR(256) DEFAULT NULL, 
   `active_on`                      VARCHAR(256) DEFAULT NULL, 
   `data_source_url`                VARCHAR(256) DEFAULT NULL, 
   `touched_run_id`                 int          not null,
   `created_by`                     VARCHAR(255) DEFAULT 'Afia', 
   `created_at`                     DATETIME DEFAULT CURRENT_TIMESTAMP, 
   `updated_at`                     TIMESTAMP DEFAULT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, 
   `md5_hash`                       VARCHAR(100) DEFAULT NULL,
   UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Afia, Task #729';
