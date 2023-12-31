CREATE TABLE VA_RAW_SCHEDULED
(
  id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  run_id int,
  report_id VARCHAR(255),
  committee_contact_id VARCHAR(255),
  first_name VARCHAR(255),
  middle_name VARCHAR(255),
  last_or_company_name VARCHAR(255),
  prefix VARCHAR(255),
  suffix VARCHAR(255),
  address_line1 VARCHAR(255),
  address_line2 VARCHAR(255),
  city VARCHAR(255),
  state_code VARCHAR(255),
  zip_code VARCHAR(255),
  is_individual VARCHAR(255),
  transaction_date DATE,
  amount VARCHAR(255),
  authorizing_name VARCHAR(255),
  item_or_service VARCHAR(255),
  schedule_D_id VARCHAR(255),
  schedule_id VARCHAR(255),
  report_uid VARCHAR(255),
  data_source_url VARCHAR(255) DEFAULT NULL,
  created_by VARCHAR(255) DEFAULT 'Umar',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  touched_run_id BIGINT,
  deleted BOOLEAN DEFAULT 0,
  md5_hash VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;
