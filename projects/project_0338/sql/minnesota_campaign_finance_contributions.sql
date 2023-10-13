CREATE TABLE `minnesota_campaign_finance_contributions_csv` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `data_source_url` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `candidate_id` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `filer` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `filing_year` int(11) DEFAULT NULL,
  `candidate_first_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `candidate_last_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `candidate_address` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `candidate_party` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `candidate_jurisdiction` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `site_source_candidate_id` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `committee_name` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `committee_type` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `committee_sub_type` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `committee_address` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `committee_party` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `registered_entity_id` varchar(255) COLLATE utf8mb4_unicode_520_ci NOT NULL,
  `source_candidate_id` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `contributor_id` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `contributor_reg_ent_id` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `contributor_full_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `contributors_first_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `contributors_last_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `contributor_type` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `zip` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `pac_affiliation` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `occupation` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `employer` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `received_date` date NOT NULL DEFAULT '0000-01-01',
  `contribution_type` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `cash_amount` decimal(15,2) NOT NULL,
  `in_kind_amount` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `in_kind_description` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `employer_master_name_id` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `contributor_employer_full_name` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `deleted_at` date DEFAULT NULL,
  `created_by` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_scrape_date` date DEFAULT NULL,
  `next_scrape_date` date DEFAULT NULL,
  `expected_scrape_frequency` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `dataset_name_prefix` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `scrape_status` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `contributor_name_clean` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `cleaned_manually` tinyint(1) DEFAULT '0',
  `md5_hash` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `touched_run_id` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `contribution_index_INDEX` (`registered_entity_id`,`received_date`,`contributor_full_name`,`cash_amount`),
  KEY `deleted_at_received_date_index` (`deleted_at`,`received_date`),
  KEY `md5_hash_index` (`md5_hash`),
  KEY `touched_index` (`touched_run_id`),
  KEY `site_source_committee_id_idx` (`registered_entity_id`),
  KEY `contributor_full_name_type_created_at_idx` (`contributor_full_name`,`contributor_type`,`created_at`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;