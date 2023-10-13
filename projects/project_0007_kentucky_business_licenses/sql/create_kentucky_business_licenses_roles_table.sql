CREATE TABLE `kentucky_business_licenses_roles` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT primary key,
  `organization_number` varchar(255) NOT NULL,
  `role` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `data_source_url` varchar(255) DEFAULT 'http://web.sos.ky.gov/ftsearch/',

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
