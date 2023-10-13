CREATE TABLE `cdc_weekly_counts_of_death_by_jurisdiction_and_cause_of_death`
(
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
    `jurisdiction` varchar(255) NOT NULL,
    `week_ending_date` date NOT NULL,
    `state_abbreviation` varchar(10) NOT NULL,
    `year` smallint NOT NULL,
    `week` tinyint NOT NULL,
    `cause_group` varchar(50) NOT NULL,
    `number_of_deaths` varchar(10) NOT NULL,
    `cause_subgroup` varchar(50) NOT NULL,
    `time_period` varchar(10) NOT NULL,
    `suppress` varchar(100) DEFAULT NULL,
    `note` varchar(500) DEFAULT NULL,
    `avg_num_of_deaths_in_time_period` varchar(10) NOT NULL,
    `dif_from_2015_2019_to_2020` varchar(10) NOT NULL,
    `pct_dif_from_2015_2019_to_2020` varchar(10) NOT NULL,
    `data_type` varchar(50) NOT NULL,
    `deleted_at` date DEFAULT NULL,

    `data_source_url` varchar(255) DEFAULT NULL,
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
    UNIQUE KEY `unique_cdc_weekly_counts_of_deaths` (`jurisdiction`,
                                                     `week_ending_date`,
                                                     `cause_group`,
                                                     `number_of_deaths`,
                                                     `cause_subgroup`,
                                                     `avg_num_of_deaths_in_time_period`,
                                                     `data_type`)
);