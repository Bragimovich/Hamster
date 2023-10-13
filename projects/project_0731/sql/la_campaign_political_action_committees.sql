CREATE TABLE `la_campaign_political_action_committees` 
(
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `pac_name` varchar(255) DEFAULT NULL,
  `pac_chair_person` varchar(255) DEFAULT NULL,
  `pac_complete_address` varchar(255) DEFAULT NULL,
  `pac_city` varchar(255) DEFAULT NULL,
  `pac_state` varchar(255) DEFAULT NULL,
  `pac_zip` varchar(255) DEFAULT NULL,
  `report_number` varchar(255) DEFAULT NULL,
  `report_link` varchar(255) DEFAULT NULL,
  `filing_date` date DEFAULT NULL,
  `report_type` varchar(255) DEFAULT NULL,
  `filer_id` varchar(255) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT 'Hassan',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` bigint(20) DEFAULT NULL,
  `touched_run_id` bigint(20) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0',
  `data_source_url` varchar(255) DEFAULT NULL,
  `md5_hash` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `md5_hash` (`md5_hash`),
  KEY `run_id` (`run_id`),
  KEY `touched_run_id` (`touched_run_id`),
  KEY `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
