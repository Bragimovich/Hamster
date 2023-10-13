CREATE TABLE `chicago_federation_musicians` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,
`full_name` varchar(255) DEFAULT NULL,
`first_name` varchar(255) DEFAULT NULL,
`middle_name` varchar(255) DEFAULT NULL,
`last_name` varchar(255) DEFAULT NULL,
`primary` varchar(255) DEFAULT NULL,
`all_instruments` varchar(255) DEFAULT NULL,
`phone_number` varchar(255) DEFAULT NULL,
`email` varchar(255) DEFAULT NULL,
`data_source_url` varchar(255) DEFAULT NULL,
`created_by` varchar(255) DEFAULT NULL,
`scrape_frequencey` varchar(255) DEFAULT NULL,
`created_at` datetime DEFAULT NULL,
`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
PRIMARY KEY (`id`),
UNIQUE KEY `unique_musician` (`full_name`, `primary`, `phone_number`, `email`)
);