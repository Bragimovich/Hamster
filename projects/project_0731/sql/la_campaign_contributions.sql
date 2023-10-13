CREATE TABLE `la_campaign_contributions` 
(
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `filer_fullname` VARCHAR(255),
  `filer_firstname` VARCHAR(255),
  `filer_lastname` VARCHAR(255),
  `report_code` VARCHAR(255),
  `report_type` VARCHAR(255),
  `report_number` VARCHAR(255),
  `report_link` VARCHAR(255),
  `type` VARCHAR(255),
  `source_name` VARCHAR(255),
  `source_complete_address` VARCHAR(255),
  `source_address` VARCHAR(255),
  `source_city` VARCHAR(255),
  `source_state` VARCHAR(255),
  `source_zip` VARCHAR(255),
  `description` VARCHAR(255),
  `contribution_type_code` VARCHAR(255),
  `contribution_date` DATE,
  `amount` DECIMAL(12,2),
  `created_by` varchar(255) DEFAULT 'Hassan',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` bigint(20) DEFAULT NULL,
  `touched_run_id` bigint(20) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0',
  `scrape_frequency` varchar(255) DEFAULT 'daily',
  `data_source_url` varchar(255) DEFAULT NULL,
  `md5_hash` varchar(150),
  PRIMARY KEY (`id`),
  UNIQUE KEY `md5_hash` (`md5_hash`),
  KEY `run_id` (`run_id`),
  KEY `touched_run_id` (`touched_run_id`),
  KEY `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
