create table `nevada_criminal_offenders`
 (
    `id`  int auto_increment   primary key,
    `run_id`   int(11),
    `first_name` varchar(255) DEFAULT NULL,
    `middle_name` varchar(255) DEFAULT NULL,
    `last_name` varchar(255) DEFAULT NULL,
    `offender_id` varchar(255) DEFAULT NULL,
    `gender` varchar(255) DEFAULT NULL,
    `ethnic` varchar(255) DEFAULT NULL,
    `approximate_age` int(11) DEFAULT NULL,
    `height_feet` int(11) DEFAULT NULL,
    `height_inches` int(11) DEFAULT NULL,
    `weight_pounds` int(11) DEFAULT NULL,
    `build` varchar(255) DEFAULT NULL,
    `complexion` varchar(255) DEFAULT NULL,
    `hair` varchar(255) DEFAULT NULL,
    `eyes` varchar(255) DEFAULT NULL,
    `agy_loc_id` varchar(255) DEFAULT NULL,
    `sec_level` varchar(255) DEFAULT NULL,
    `pri_fel_flag` varchar(255) DEFAULT NULL,
    `year` varchar(255) DEFAULT NULL,
    `scrape_dev_name` varchar(255) DEFAULT 'Adeel',
    `aliases` text DEFAULT NULL,
    `data_source_url` varchar(255) DEFAULT NULL,
    `scrape_frequency`           VARCHAR(255)       DEFAULT NULL,
    `last_scrape_date` date DEFAULT NULL,
    `next_scrape_date` date DEFAULT NULL,
    `expected_scrape_frequency` varchar(255) DEFAULT NULL,
    `dataset_name_prefix` varchar(255) DEFAULT NULL,
    `scrape_status` varchar(255) DEFAULT NULL,
    `pl_gather_task_id` int(11) DEFAULT NULL,
    `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,    
    `md5hash` varchar(100) DEFAULT NULL,
    `is_deleted` int(1) DEFAULT '0',
    UNIQUE KEY `unique_data` (`md5_hash`)
  ) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
