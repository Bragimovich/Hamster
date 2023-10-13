CREATE TABLE `new_tennessee_campaign_finance_contributions`
(
	`id` 			                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
	`report_id` 					int,
	`committe_id` 					int,
	`contributor_name` 				varchar(255),
	`contributor_address` 			varchar(255),
	`contributor_city_state_zip` 	varchar(255),
	`date` 							Date,
	`amount` 						decimal(12,2),
	`received_for` 					varchar(255),
	`c_p` 							varchar(255),
	`depreciated` 					int(1),
	`created_by`                    VARCHAR(255) DEFAULT 'Aqeel',
	`created_at`                    DATETIME     DEFAULT CURRENT_TIMESTAMP,
	`updated_at`                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`scrape_frequency`              VARCHAR(255) DEFAULT 'Monthly',
	`data_source_url` 				varchar(255),
	`run_id`                 		BIGINT(20),
	`touched_run_id`          		BIGINT,
	`deleted`                 		BOOLEAN            DEFAULT 0,
	`md5_hash`                      VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('',report_id, committe_id, contributor_name, contributor_address, contributor_city_state_zip, date, amount, received_for, c_p, depreciated))) STORED,
	UNIQUE KEY `md5` (`md5_hash`),
	INDEX `run_id` (`run_id`),
	INDEX `touched_run_id` (`touched_run_id`),
	INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
