CREATE TABLE `iowa_voter_registrations` 
(
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `run_id` bigint(20) DEFAULT NULL,
  `source_date` varchar(255) DEFAULT NULL,
  `year` varchar(255) DEFAULT NULL,
  `day` varchar(255) DEFAULT NULL,
  `month` varchar(255) DEFAULT NULL,
  `county` varchar(255) DEFAULT NULL,
  `democratic_active` varchar(255) DEFAULT NULL,
  `republican_active` varchar(255) DEFAULT NULL,
  `libertarian_active` varchar(255) DEFAULT NULL,
  `no_party_active` varchar(255) DEFAULT NULL,
  `other_active` varchar(255) DEFAULT NULL,
  `total_active` varchar(255) DEFAULT NULL,
  `democratic_inactive` varchar(255) DEFAULT NULL,
  `republican_inactive` varchar(255) DEFAULT NULL,
  `libertarian_inactive` varchar(255) DEFAULT NULL,
  `no_party_inactive` varchar(255) DEFAULT NULL,
  `other_inactive` varchar(255) DEFAULT NULL,
  `total_inactive` varchar(255) DEFAULT NULL,
  `grand_total` varchar(255) DEFAULT NULL,
  `scrape_dev_name` varchar(255) DEFAULT 'Aqeel',
  `data_source_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequency` varchar(255) DEFAULT 'Monthly',
  `last_scrape_date` date DEFAULT NULL,
  `next_scrape_date` date DEFAULT NULL,
  `expected_scrape_frequency` varchar(255) DEFAULT 'Monthly',
  `dataset_name_prefix` varchar(255) DEFAULT NULL,
  `scrape_status` varchar(255) DEFAULT 'Live',
  `pl_gather_task_id` int(11) DEFAULT NULL,
  `md5_hash` varchar(100) GENERATED ALWAYS AS (md5(concat_ws('',source_date,year,day,month,county,democratic_active,republican_active,libertarian_active,no_party_active,other_active,total_active,democratic_inactive,republican_inactive,libertarian_inactive,no_party_inactive,other_inactive,total_inactive,grand_total))) STORED unique key,
  PRIMARY KEY (`id`),
  ) DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci;