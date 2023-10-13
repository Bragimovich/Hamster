CREATE TABLE mo_cc_case_activities
(
  `id` BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id` INT(11) DEFAULT 91,
  `case_id` VARCHAR(255),
  `activity_date` DATE,
  `activity_type` VARCHAR(255),
  `activity_decs` MEDIUMTEXT,
  `activity_pdf` VARCHAR(255),
  `run_id` BIGINT(20),
  `data_source_url` VARCHAR(255) DEFAULT 'https://www.courts.mo.gov/casenet/cases/filingDateSearch.do',
  `created_by` VARCHAR(255) DEFAULT 'Umar',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id` BIGINT,
  `deleted` BOOLEAN DEFAULT 0,
  `md5_hash` VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX court_id (court_id),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;
