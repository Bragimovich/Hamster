CREATE TABLE `north_carolina_business_licenses_csv_files_by_year` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,
`file_year` varchar(255) NOT NULL,
`date_start` date NOT NULL,
`date_end` date NOT NULL,
`file_found` boolean DEFAULT FALSE,
`file_downloaded` boolean DEFAULT FALSE,
`scrape_dev_name` varchar(255) DEFAULT NULL,
`data_source_url` varchar(255) DEFAULT NULL,
`created_at` DATETIME           DEFAULT CURRENT_TIMESTAMP,
`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (`id`),
UNIQUE (file_year, date_start, date_end)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Table use to control which CSV files for which year was found/downloaded for north_carolina_business_licenses';
