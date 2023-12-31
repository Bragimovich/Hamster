CREATE TABLE `cdc_covid_19_case_surveillance`(
 `id` bigint(20) NOT NULL AUTO_INCREMENT  PRIMARY KEY,
 `year` varchar(255),
 `cdc_case_earliest_dt` Date,
 `cdc_report_date` Date,
 `pos_spec_date` Date,
 `onset_date` Date,
 `current_status` varchar(255),
 `sex` varchar(255),
 `age_group` varchar(255),
 `race_and_ethnicity` varchar(255),
 `hospital` varchar(255),
 `icu` varchar(255),
 `death` varchar(255),
 `medical_condition` varchar(255),
 `md5_hash` varchar(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', CAST(cdc_case_earliest_dt as CHAR), CAST(cdc_report_date as CHAR), CAST(pos_spec_date as CHAR), CAST(onset_date as CHAR), current_status,  sex, age_group, race_and_ethnicity, hospital, icu, death, medical_condition))) STORED,
 `data_source_url` varchar(255)  DEFAULT 'https://data.cdc.gov/api/views/vbim-akqf/rows.csv?accessType=DOWNLOAD',
 `last_scrape_date`  Date,
 `next_scrape_date`  Date,
 `expected_scrape_frequency` Date,
 `run_id`    int,
 `touch_run_id` int,
 `is_deleted`   int  DEFAULT 0;
 `pl_gather_task_id`  bigint               DEFAULT '174735332',
 `scrape_status`      varchar(255)         DEFAULT 'Live',
 `dataset_name_prefix`      varchar(255)         DEFAULT 'cdc_covid_19_case_surveillance',
 `scrape_frequency`   varchar(255)         DEFAULT 'Monthly',
 `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
 `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
 `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
