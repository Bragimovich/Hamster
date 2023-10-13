create unique index harris_county_tx_delinquent_tax_sale_property__uindex
	on gun_violence_incidents_daily_mains (
	    address, precinct, sale_nr, type, cause_nr, judgment, tax_years_in_judgement, run_id
);

CREATE TABLE `harris_county_tx_delinquent_tax_sale_property` (
`id` bigint(20) NOT NULL AUTO_INCREMENT,

`address` varchar(255) DEFAULT NULL,
`city` varchar(255) DEFAULT NULL,
`state` varchar(255) DEFAULT NULL,
`zip` varchar(255) DEFAULT NULL,
`precinct` varchar(255) DEFAULT NULL,

`sale_nr` varchar(255) DEFAULT NULL,
`type` varchar(255) DEFAULT NULL,
`cause_nr` varchar(255) DEFAULT NULL,
`judgment` varchar(255) DEFAULT NULL,
`tax_years_in_judgement` varchar(255) DEFAULT NULL,
`minimum_bid` varchar(255) DEFAULT NULL,
`adjudjed_value` varchar(255) DEFAULT NULL,
`hcad_account_nr` varchar(255) DEFAULT NULL,
`hcad_account_link` varchar(255) DEFAULT NULL,
`tax_sale_link` varchar(255) DEFAULT NULL,
`description` varchar(255) DEFAULT NULL,

`scrape_dev_name` varchar(255) DEFAULT 'dsuschinsky',
`data_source_url` varchar(255) DEFAULT 'https://www.hctax.net/Property/listings/taxsalelisting',
`created_at` datetime DEFAULT NULL,
`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`last_scrape_date` date DEFAULT NULL,
`next_scrape_date` date DEFAULT NULL,
`expected_scrape_frequency` varchar(255) DEFAULT 'monthly',
`scrape_status` varchar(255) DEFAULT NULL,
`pl_gather_task_id` varchar(255) DEFAULT NULL,
`run_id` int(11),

PRIMARY KEY (`id`),
UNIQUE KEY `unique_harris_county` (
    `address`, `precinct`, `sale_nr`, `type`, `cause_nr`, `judgment`, `tax_years_in_judgement`, `run_id`
)
);