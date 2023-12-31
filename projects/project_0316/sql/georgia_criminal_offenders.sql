CREATE TABLE `georgia_criminal_offenders` 
(
  `id` bigint NOT NULL AUTO_INCREMENT,
  `year` varchar(255) DEFAULT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `middle_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `gdc_ID` varchar(255) DEFAULT NULL,
  `year_of_birth` varchar(255) DEFAULT NULL,
  `race` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `height` varchar(255) DEFAULT NULL,
  `weight` varchar(255) DEFAULT NULL,
  `eye_color` varchar(255) DEFAULT NULL,
  `hair_color` varchar(255) DEFAULT NULL,
  `scar_marks_tattoos` varchar(255) DEFAULT NULL,
  `major_offense` varchar(255) DEFAULT NULL,
  `most_recent_institution` varchar(255) DEFAULT NULL,
  `max_possible_release_date` varchar(255) DEFAULT NULL,
  `actual_release_date` varchar(255) DEFAULT NULL,
  `current_status` varchar(255) DEFAULT NULL,
  `md5_hash` varchar(150) GENERATED ALWAYS AS (md5(concat_ws('',full_name,first_name,gdc_ID,year_of_birth,race,gender,height,weight,eye_color,hair_color,alien_no,major_offense,most_recent_institution,max_possible_release_date,actual_release_date,current_status))) STORED DEFAULT NULL,
  `is_deleted` int DEFAULT '0',
  `scrape_dev_name` varchar(255) DEFAULT 'Adeel',
  `data_source_url` varchar(255) DEFAULT 'https://gdc.ga.gov/GDC/Offender/Query',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequency` varchar(255) DEFAULT 'Monthly',
  `last_scrape_date` date DEFAULT NULL,
  `next_scrape_date` date DEFAULT NULL,
  `expected_scrape_frequency` varchar(255) DEFAULT 'Monthly',
  `dataset_name_prefix` varchar(255) DEFAULT NULL,
  `scrape_status` varchar(255) DEFAULT 'Live',
  `pl_gather_task_id` int DEFAULT NULL,
  `alien_no` varchar(255) DEFAULT NULL,
  `letters` varchar(255) DEFAULT NULL,
  `aliases` text,
  `run_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
