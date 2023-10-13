CREATE TABLE `az_assessment` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,
`year` varchar(255) DEFAULT NULL,
`fiscal_year` varchar(255) DEFAULT NULL,
`school_type` varchar(255) DEFAULT NULL,
`school_entity_id` int(11) DEFAULT NULL,
`school_name` varchar(255) DEFAULT NULL,
`school_ctds_num` varchar(255) DEFAULT NULL,
`charter` varchar(255) DEFAULT NULL,
`alternative_school` varchar(255) DEFAULT NULL,
`district_name` varchar(255) DEFAULT NULL,
`district_entity_id` int(11) DEFAULT NULL,
`district_ctds_num` varchar(255) DEFAULT NULL,
`district` varchar(255) DEFAULT NULL,
`county` varchar(255) DEFAULT NULL,
`test_level` varchar(255) DEFAULT NULL,
`subgroup` varchar(255) DEFAULT NULL,
`subject` varchar(255) DEFAULT NULL,
`number_tested` varchar(255) DEFAULT NULL,
`percent_passing` varchar(255) DEFAULT NULL,
`percent_proficiency_level_1` varchar(255) DEFAULT NULL,
`percent_proficiency_level_2` varchar(255) DEFAULT NULL,
`percent_proficiency_level_3` varchar(255) DEFAULT NULL,
`percent_proficiency_level_4` varchar(255) DEFAULT NULL,
`data_type` varchar(255) DEFAULT NULL,
`data_source_url` varchar(255) DEFAULT NULL,
`scrape_dev_name` varchar(255) DEFAULT NULL,
`report_date` DATE,
`scrape_frequency` varchar(255) DEFAULT NULL,
`created_at` datetime DEFAULT NULL,
`update_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`last_scrape_date` date DEFAULT NULL,
`next_scrape_date` date DEFAULT NULL,
`expected_scrape_frequency` varchar(255) DEFAULT NULL,
`dataset_name_prefix` varchar(255) DEFAULT NULL,
`scrape_status` varchar(255) DEFAULT NULL,
`pl_gather_task_id` varchar(255) DEFAULT NULL,
PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET = `utf8mb4`
 COLLATE = utf8mb4_unicode_520_ci;






