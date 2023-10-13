CREATE TABLE md_dccc_case_judgment
(
  `id` BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id` INT DEFAULT 91,
  `case_id` VARCHAR(255),
  `complaint_id` VARCHAR(255),
  `party_name` VARCHAR(255),
  `fee_amount` VARCHAR(255),
  `judgment_amount` VARCHAR(255),
  `judgment_date` VARCHAR(255),
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
