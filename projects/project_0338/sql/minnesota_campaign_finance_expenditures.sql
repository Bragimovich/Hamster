CREATE TABLE `minnesota_campaign_finance_expenditures_csv` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `data_source_url` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `registered_entity_id` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `reg_ent_full_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `registered_entity_type` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `registered_entity_subtype` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `vendor_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `vendor_master_name_id` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `vendor_address1` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `vendor_address2` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `vendor_city` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `vendor_state` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `vendor_zipcode` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `expenditure_amount` decimal(15,2) NOT NULL,
  `expenditure_unpaid_amount` decimal(15,2) NOT NULL,
  `expenditure_date` date DEFAULT NULL,
  `purpose` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `filing_year` int(11) DEFAULT NULL,
  `expenditure_type` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `in_kind_description` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `expenditure_in_kind` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `affected_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `affected_reg_num` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `deleted_at` date DEFAULT NULL,
  `created_by` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_scrape_date` date DEFAULT NULL,
  `next_scrape_date` date DEFAULT NULL,
  `expected_scrape_frequency` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `dataset_name_prefix` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `scrape_status` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `md5_hash` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `touched_run_id` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `deleted_at_expenditure_date_index` (`expenditure_date`,`deleted_at`),
  KEY `deleted_at_index` (`deleted_at`),
  KEY `touched_index` (`touched_run_id`),
  KEY `md5_hash_index` (`md5_hash`)
)DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;
