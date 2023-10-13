CREATE TABLE `georgia_criminal_offenders_offenses` 
(
  `id` bigint NOT NULL AUTO_INCREMENT,
  `year` varchar(255) DEFAULT NULL,
  `gdc_ID` varchar(255) DEFAULT NULL,
  `sentence_type` varchar(50) DEFAULT NULL,
  `case_number` varchar(50) DEFAULT NULL,
  `offense` varchar(255) DEFAULT NULL,
  `conviction_county` varchar(150) DEFAULT NULL,
  `crime_commit_date` date DEFAULT NULL,
  `sentence_length` varchar(255) DEFAULT NULL,
  `md5_hash` varchar(150) GENERATED ALWAYS AS (md5(concat_ws('',gdc_ID,sentence_type,case_number,offense,conviction_county,crime_commit_date,sentence_length))) STORED DEFAULT NULL,
  `is_deleted` int DEFAULT '0',
  `scrape_dev_name` varchar(255) DEFAULT 'Adeel',
  `data_source_url` varchar(255) DEFAULT 'https://gdc.ga.gov/GDC/Offender/Query',
  `scrape_frequency` varchar(255) DEFAULT 'Monthly',
  `pl_gather_task_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
