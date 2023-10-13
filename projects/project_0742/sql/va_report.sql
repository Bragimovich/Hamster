CREATE TABLE VA_RAW_REPORT
(
  `id` BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  run_id int,
  `run_id` int,
  `report_id` VARCHAR(255),
  `committee_code` VARCHAR(255),
  `committee_name` VARCHAR(255),
  `committee_type` VARCHAR(255),
  `candidate_name` VARCHAR(255),
  `is_state_wide` VARCHAR(255),
  `is_general_assembly` VARCHAR(255),
  `is_local` VARCHAR(255),
  `party` VARCHAR(255),
  `fec_number` VARCHAR(255),
  `report_year` VARCHAR(255),
  `filing_date` DATE,
  `start_date` DATE,
  `end_date` DATE,
  `address_line1` VARCHAR(255),
  `address_line2` VARCHAR(255),
  `address_line3` VARCHAR(255),
  `city` VARCHAR(255),
  `state_code` VARCHAR(255),
  `zip_code` VARCHAR(255),
  `filing_type` VARCHAR(255),
  `is_final_report` VARCHAR(255),
  `is_amendment` VARCHAR(255),
  `amendment_count` VARCHAR(255),
  `submitter_phone` VARCHAR(255),
  `submitter_email` VARCHAR(255),
  `election_cycle` VARCHAR(255),
  `election_cycle_start_date` DATE,
  `election_cycle_end_date` DATE,
  `office_sought` VARCHAR(255),
  `district` VARCHAR(255),
  `no_activity` VARCHAR(255),
  `balance_last_reporting_period` VARCHAR(255),
  `date_of_referendum` DATE,
  `submitted_date` DATE,
  `account_id` VARCHAR(255),
  `due_date` VARCHAR(255),
  `is_xml_upload` VARCHAR(255),
  `report_uid` VARCHAR(255),
  `data_source_url` VARCHAR(255) DEFAULT NULL,
  `created_by` VARCHAR(255) DEFAULT 'Umar',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id` BIGINT,
  `deleted` BOOLEAN DEFAULT 0,
  `md5_hash` VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;