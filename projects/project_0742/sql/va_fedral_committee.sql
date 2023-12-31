CREATE TABLE VA_RAW_FederalPoliticalActionCommittee
(
  id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  committee_code VARCHAR(255),
  run_id int,
  committee_name VARCHAR(255),
  committee_acronym VARCHAR(255),
  is_amendment VARCHAR(255),
  date_changes_took_effect VARCHAR(255),
  FEC_identification_number VARCHAR(255),
  committee_street_address VARCHAR(255),
  committee_suite VARCHAR(255),
  committee_city VARCHAR(255),
  committee_state VARCHAR(255),
  committee_zip_code VARCHAR(255),
  committee_email_address VARCHAR(255),
  committee_business_phone VARCHAR(255),
  committee_website VARCHAR(255),
  treasurer_first_name VARCHAR(255),
  treasurer_last_name VARCHAR(255),
  treasurer_email VARCHAR(255),
  treasurer_day_time_phone_number VARCHAR(255),
  no_longer_active_in_virginia VARCHAR(255),
  submitted_on DATE,
  accepted_on DATE,
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
