CREATE TABLE `cdc_excess_deaths` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,

`data_source_url` varchar(255) DEFAULT NULL,

`week_ending_date` date NOT NULL,
`state` varchar(30) DEFAULT NULL,
`observed_number` int(11) DEFAULT NULL,
`upper_bound_threshold` int(11) DEFAULT NULL,
`exceeds_threshold` varchar(5) DEFAULT NULL,
`average_expected_count` int(11) DEFAULT NULL,
`excess_lower_estimate` int(11) DEFAULT NULL,
`excess_higher_estimate` int(11) DEFAULT NULL,
`year` int(11) DEFAULT NULL,
`total_excess_lower_estimate_in_2020` int(11) DEFAULT NULL,
`total_excess_higher_estimate_in_2020` int(11) DEFAULT NULL,
`percent_excess_lower_estimate` decimal(8,2) DEFAULT NULL,
`percent_excess_higher_estimate` decimal(8,2) DEFAULT NULL,
`data_type` varchar(30) DEFAULT NULL,
`outcome` varchar(40) DEFAULT NULL,
`suppress` varchar(70) DEFAULT NULL,
`note` varchar(400) DEFAULT NULL,

`deleted_at` date DEFAULT NULL,

`created_by` varchar(255) DEFAULT NULL,
`created_at` datetime DEFAULT NULL,
`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`last_scrape_date` date DEFAULT NULL,
`next_scrape_date` date DEFAULT NULL,
`expected_scrape_frequency` varchar(255) DEFAULT NULL,
`dataset_name_prefix` varchar(255) DEFAULT NULL,
`scrape_status` varchar(255) DEFAULT NULL,
`pl_gather_task_id` varchar(255) DEFAULT NULL,
PRIMARY KEY (`id`),
UNIQUE KEY `unique_cdc_excess_deaths` (`week_ending_date`, `data_type`, `outcome`)
);