CREATE TABLE VA_RAW_PoliticalPartyCommittee
(
  id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  run_id int,
  party_affiliation VARCHAR(200),
  committee_code VARCHAR(200),
  committee_name VARCHAR(200),
  is_amendment VARCHAR(200),
  date_changes_took_effect VARCHAR(200),
  committee_street_address VARCHAR(200),
  committee_suite VARCHAR(200),
  committee_city VARCHAR(200),
  committee_state VARCHAR(200),
  committee_zip_code VARCHAR(200),
  committee_email_address VARCHAR(200),
  committee_phone VARCHAR(200),
  committee_website VARCHAR(200),
  treasurer_salutation VARCHAR(200),
  treasurer_first_name VARCHAR(200),
  treasurer_middle_name VARCHAR(200),
  treasurer_last_name VARCHAR(200),
  treasurer_suffix VARCHAR(200),
  treasurer_business_address VARCHAR(200),
  treasurer_business_suite_number VARCHAR(200),
  treasurer_business_city VARCHAR(200),
  treasurer_business_state VARCHAR(200),
  treasurer_business_zip_code VARCHAR(200),
  treasurer_street_address VARCHAR(200),
  treasurer_suite VARCHAR(200),
  treasurer_city VARCHAR(200),
  treasurer_state VARCHAR(200),
  treasurer_zip_code VARCHAR(200),
  treasurer_email VARCHAR(200),
  treasurer_day_time_phone_number VARCHAR(200),
  custodian_position_or_title VARCHAR(200),
  custodian_salutation VARCHAR(200),
  custodian_first_name VARCHAR(200),
  custodian_middle_name VARCHAR(200),
  custodian_last_name VARCHAR(200),
  custodian_suffix VARCHAR(200),
  custodian_business_address VARCHAR(200),
  custodian_business_suite_number VARCHAR(200),
  custodian_business_city VARCHAR(200),
  custodian_business_state VARCHAR(200),
  custodian_business_zip_code VARCHAR(200),
  custodian_street_address VARCHAR(200),
  custodian_suite VARCHAR(200),
  custodian_city VARCHAR(200),
  custodian_state VARCHAR(200),
  custodian_zip_code VARCHAR(200),
  address_maintain_street_address VARCHAR(200),
  address_maintain_suite VARCHAR(200),
  address_maintain_city VARCHAR(200),
  address_maintain_state VARCHAR(200),
  address_maintain_zip_code VARCHAR(200),
  filing_method VARCHAR(200),
  approved_vendor VARCHAR(200),
  submitted_on VARCHAR(200),
  accepted_on VARCHAR(200),
  district_name VARCHAR(200),
  custodian_email VARCHAR(200),
  custodian_day_time_phone_number VARCHAR(200),
  date_first_contribution_accepted VARCHAR(200),
  date_first_expenditure_made VARCHAR(200),
  date_treasurer_appointed VARCHAR(200),
  date_campaign_depository_designated VARCHAR(200),
  committee_scope VARCHAR(200),
  locality_name VARCHAR(200),
  officer1_name VARCHAR(200),
  officer1_title VARCHAR(200),
  officer1_day_time_phone VARCHAR(200),
  officer2_name VARCHAR(200),
  officer2_title VARCHAR(200),
  officer2_day_time_phone VARCHAR(200),
  data_source_url VARCHAR(200) DEFAULT NULL,
  created_by VARCHAR(200) DEFAULT 'Umar',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  touched_run_id BIGINT,
  deleted BOOLEAN DEFAULT 0,
  md5_hash VARCHAR(200),
  UNIQUE KEY md5 (md5_hash),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;