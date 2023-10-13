create table `hr_um_annual_salary_rate`
(
  `id`  int auto_increment   primary key,
  `run_id`  int,
  `campus`  varchar (255) DEFAULT NULL,
  `name` varchar (255) DEFAULT NULL,
  `appointment_title` varchar (255) DEFAULT NULL,
  `appointment_dep` varchar (255) DEFAULT NULL,
  `appt_annual_ftr` FLOAT DEFAULT NULL,
  `appt_ftr_basis` varchar (25) DEFAULT NULL,
  `appt_fraction`FLOAT DEFAULT NULL,
  `amt_of_salary_paid_from_genl_fund` FLOAT DEFAULT NULL,
  `as_of_date`  date,
  `destribution_date`  date,
  `ex_page_num`  int,
  `data_source_url`     varchar (350),
  `created_by`           VARCHAR(255)       DEFAULT 'Muhammad Qasim',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  `touched_run_id`  int DEFAULT 0,
  `md5_hash` varchar(100),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
