CREATE TABLE ks_employee_salaries
(
  id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  fiscal_year INT,
  agency_number INT,
  agency_name VARCHAR(255),
  employee_name VARCHAR(255),
  job_title VARCHAR(255),
  total_gross_pay DECIMAL(10, 2),
  overtime_pay DECIMAL(10, 2),
  pay_rate DECIMAL(10, 2),
  frequency Varchar(255),
  data_source_url VARCHAR(100),
  created_by VARCHAR(255) DEFAULT 'Umar',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  run_id BIGINT(20),
  touched_run_id BIGINT,
  deleted BOOLEAN DEFAULT 0,
  md5_hash VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX run_id (run_id),
  INDEX touched_run_id (touched_run_id),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;
