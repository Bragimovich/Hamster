CREATE TABLE `la_campaign_committees` 
(
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `committee_name` VARCHAR(2048),
  `committee_complete_address` VARCHAR(1024),
  `committee_city` VARCHAR(256),
  `committee_state` VARCHAR(256),
  `committee_zip` VARCHAR(64),
  `report_number` VARCHAR(255),
  `report_link` VARCHAR(255),
  `filing_date` DATE,
  `created_by` varchar(255) DEFAULT 'Hassan',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` bigint(20) DEFAULT NULL,
  `touched_run_id` bigint(20) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0',
  `data_source_url` varchar(255) DEFAULT NULL,
  `scrape_frequency` varchar(255) DEFAULT 'daily',
  `md5_hash` varchar(150),
  PRIMARY KEY (`id`),
  UNIQUE KEY `md5_hash` (`md5_hash`),
  KEY `run_id` (`run_id`),
  KEY `touched_run_id` (`touched_run_id`),
  KEY `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
