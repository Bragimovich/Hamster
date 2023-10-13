create table `tx_employee_salary`
(
  `id`                          bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY, 
  `run_id`                      INT,
  `state_number`                INT,
  `agency`                      INT,
  `agency_name`                 VARCHAR(255),
  `last_name`                   VARCHAR(255),
  `first_name`                  VARCHAR(255),
  `middle_name`                 VARCHAR(255),
  `class_code`                  VARCHAR(255),
  `class_title`                 VARCHAR(255),
  `ethnicity`                   VARCHAR(255),
  `gender`                      VARCHAR(255),
  `status`                      VARCHAR(255),
  `employ_date`                 DATE,
  `hrly_rate`                   decimal(10,5),
  `hrs_per_wk`                  INT(11),
  `monthly`                     decimal(10,2),
  `annual`                      decimal(10,5),
  `scrape_dev_name`             VARCHAR(255) DEFAULT 'Aqeel Anwar',
  `data_source_url`             text default "https://salaries.texastribune.org/",
  `created_at`                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequency`            VARCHAR(255) DEFAULT 'yearly',
  'md5_hash'                    VARCHAR (255)GENERATED ALWAYS AS(md5(concat_ws('',CAST(state_number AS CHAR),CAST(agency AS CHAR),agency_name,last_name,first_name,middle_name,class_code,class_title,ethnicity,gender,status,CAST(employ_date AS CHAR),CAST(hrly_rate AS CHAR),CAST(hrs_per_wk AS CHAR),CAST(monthly AS CHAR),CAST(annual AS CHAR),duplicated,multiple_full_time_jobs, combined_multiple_jobs, hide_from_search, summed_annual_salary, source_updated_at))) STORED
  `duplicated`                  VARCHAR (255),
  `multiple_full_time_jobs`     VARCHAR (255),
  `combined_multiple_jobs`      VARCHAR (255),
  `hide_from_search`            VARCHAR (255),
  `summed_annual_salary`        decimal(10,2),
  'source_updated_at'           DATE
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
