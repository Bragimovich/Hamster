CREATE TABLE `pennsylvania_voter_registrations` 
(
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `run_id` bigint(20) DEFAULT NULL,
  `source_date` varchar(255) DEFAULT NULL,
  `year` varchar(255) DEFAULT NULL,
  `day` varchar(255) DEFAULT NULL,
  `month` varchar(255) DEFAULT NULL,
  `county` varchar(255) DEFAULT NULL,
  `id_number` varchar(255) DEFAULT NULL,
  `count_of_democratic_voters` varchar(255) DEFAULT NULL,
  `count_of_republican_voters` varchar(255) DEFAULT NULL,
  `count_of_no_affiliation_voters` varchar(255) DEFAULT NULL,
  `count_of_all_others_voters` varchar(255) DEFAULT NULL,
  `total_count_of_all_voters` varchar(255) DEFAULT NULL,
  `scrape_dev_name` varchar(255) DEFAULT 'Adeel',
  `data_source_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequency` varchar(255) DEFAULT 'Daily',
  `last_scrape_date` date DEFAULT NULL,
  `next_scrape_date` date DEFAULT NULL,
  `expected_scrape_frequency` varchar(255) DEFAULT 'Daily',
  `dataset_name_prefix` varchar(255) DEFAULT NULL,
  `scrape_status` varchar(255) DEFAULT 'Live',
  `deleted` bigint(20) DEFAULT '0',
  `pl_gather_task_id` int(11) DEFAULT NULL,
  `md5_hash` varchar(100) GENERATED ALWAYS AS (md5(concat_ws('',`source_date`,`year`,`month`,`county`,`id_number`,`count_of_democratic_voters`,`count_of_republican_voters`,`count_of_no_affiliation_voters`,`count_of_all_others_voters`,`total_count_of_all_voters`))) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
 COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Adeel';
