CREATE TABLE `north_carolina_business_licenses_html_pitem_id_downloaded` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,
`date_formed` date DEFAULT NULL,
`pitem_id` varchar(255) DEFAULT NULL,
`scraped_by_pitem_id` boolean DEFAULT FALSE,
`scrape_dev_name` varchar(255) DEFAULT NULL,
`created_at` DATETIME           DEFAULT CURRENT_TIMESTAMP,
`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (`id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Track which HTML file was downloaded by pitem_id';
