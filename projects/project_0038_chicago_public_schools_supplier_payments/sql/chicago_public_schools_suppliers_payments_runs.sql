CREATE TABLE `chicago_public_schools_suppliers_payments_runs` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,
`created_at` datetime DEFAULT NULL,
`last_scrape_date` date DEFAULT NULL,
PRIMARY KEY (`id`),
UNIQUE KEY `unique_committee` (`created_at`, `last_scrape_date`),
FOREIGN KEY (id) REFERENCES `chicago_public_schools_suppliers_payments`(run_id)
);
