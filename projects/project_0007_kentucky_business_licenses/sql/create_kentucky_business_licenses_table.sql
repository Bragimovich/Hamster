CREATE TABLE `kentucky_business_licenses` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT primary key,
  `organization_number` varchar(255) DEFAULT NULL,
  `business_name` varchar(255) DEFAULT NULL,
  `is_profit_org` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `standing` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `file_date` datetime DEFAULT NULL,
  `principal_office_address` varchar(255) DEFAULT NULL,
  `principal_office_city_state_zip` varchar(255) DEFAULT NULL,
  `managed_by` varchar(255) DEFAULT NULL,

  `company_type` varchar(255) DEFAULT NULL,
  `organization_date` date DEFAULT NULL,
  `last_annual_report` datetime DEFAULT NULL,
  `registered_agent` varchar(255) DEFAULT NULL,
  `authorized_shares` varchar(255) DEFAULT NULL,
  `license_url` varchar(255) DEFAULT 'http://web.sos.ky.gov/ftsearch/',

  `created_by` varchar(255) default 'Frank Rao' NULL,
  `created_at` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `expected_scrape_frequency` varchar(255) DEFAULT 'weekly' NULL,
  `run_id` int(11) DEFAULT NULL,
  `touched_run_id` int(11) NOT NULL,
  `md5_hash` varchar(255) DEFAULT NULL,
  `deleted` int(11) NOT NULL DEFAULT 0,

  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'The Scrape made by Frank Rao task #7 ';

  ALTER TABLE `kentucky_business_licenses` ADD INDEX `license_url` (`license_url`);
