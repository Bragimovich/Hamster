CREATE TABLE `kansas_campaign_finance_runs` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,
`created_at` datetime DEFAULT NULL,
`last_scrape_date` date DEFAULT NULL,
PRIMARY KEY (`id`)
);
