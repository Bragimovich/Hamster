CREATE TABLE ny_public_salaries
(
  id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255),
  employer VARCHAR(255),
  total_pay VARCHAR(255),
  subagency VARCHAR(255),
  title VARCHAR(255),
  rate_of_pay VARCHAR(255),
  pay_year VARCHAR(255),
  pay_basis VARCHAR(255),
  branch VARCHAR(255),
  year VARCHAR(255),
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
