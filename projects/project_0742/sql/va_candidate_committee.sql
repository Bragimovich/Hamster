CREATE TABLE VA_RAW_CandidateCampaignCommittee
(
  id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  committee_code VARCHAR(255),
  run_id int,
  committee_name VARCHAR(255),
  is_amendment VARCHAR(255),
  date_changes_took_effect DATE,
  office_type VARCHAR(255),
  locality_name VARCHAR(255),
  district_name VARCHAR(255),
  office_sought_name VARCHAR(255),
  election_name VARCHAR(255),
  election_date DATE,
  political_party_name VARCHAR(255),
  committee_street_address VARCHAR(255),
  committee_suite VARCHAR(255),
  committee_city VARCHAR(255),
  committee_state VARCHAR(255),
  committee_zip_code VARCHAR(255),
  committee_email_address VARCHAR(255),
  committee_phone VARCHAR(255),
  committee_website VARCHAR(255),
  voter_registration_id VARCHAR(255),
  candidate_salutation VARCHAR(255),
  candidate_first_name VARCHAR(255),
  candidate_middle_name VARCHAR(255),
  candidate_last_name VARCHAR(255),
  candidate_suffix VARCHAR(255),
  candidate_street_address VARCHAR(255),
  candidate_suite_number VARCHAR(255),
  candidate_city VARCHAR(255),
  candidate_state VARCHAR(255),
  candidate_zip_code VARCHAR(255),
  candidate_email_address VARCHAR(255),
  candidate_day_time_phone_number VARCHAR(255),
  treasurer_voter_id VARCHAR(255),
  treasurer_salutation VARCHAR(255),
  treasurer_first_name VARCHAR(255),
  treasurer_middle_name VARCHAR(255),
  treasurer_last_name VARCHAR(255),
  treasurer_suffix VARCHAR(255),
  treasurer_street_address VARCHAR(255),
  treasurer_suite VARCHAR(255),
  treasurer_city VARCHAR(255),
  treasurer_state VARCHAR(255),
  treasurer_zip_code VARCHAR(255),
  treasurer_email VARCHAR(255),
  treasurer_day_time_phone_number VARCHAR(255),
  filing_method VARCHAR(255),
  approved_vendor VARCHAR(255),
  submitted_on DATE,
  accepted_on DATE,
  candidate_county_or_city_of_residence VARCHAR(255),
  treasurer_county_or_city_of_residence VARCHAR(255),
  candidateIs_registered_to_vote VARCHAR(255),
  treasurerIs_registered_to_vote VARCHAR(255),
  date_first_contribution_accepted VARCHAR(255),
  date_first_expenditure_made VARCHAR(255),
  date_campaign_depository_designated VARCHAR(255),
  date_treasurer_appointed DATE,
  date_statement_of_qualification_filed VARCHAR(255),
  date_filing_fee_paid_for_party_nomination VARCHAR(255),
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