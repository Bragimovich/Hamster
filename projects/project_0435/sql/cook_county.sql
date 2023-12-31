CREATE TABLE `cook_county_death_cause`(
 `id` bigint(20) NOT NULL AUTO_INCREMENT  PRIMARY KEY,
 `case_number` varchar(255),
 `incident_date` Date,
 `death_date` Date,
 `age` varchar(255),
 `gender` varchar(255),
 `race` varchar(255),
 `latino` varchar(255),
 `manner_of_death` varchar(255),
 `primary_cause` varchar(255),
 `primary_cause_line_a` varchar(255),
 `primary_cause_line_b` varchar(255),
 `primary_cause_line_c` varchar(255),
 `secondary_cause` varchar(255),
 `gun_related` varchar(255),
 `opioid_related` varchar(255),
 `cold_related`   varchar(255),
 `heat_related` varchar(255),
 `incident_address` varchar(255),
 `incident_city` varchar(255),
 `incident_zipcode` varchar(255),
 `longitude` varchar(255),
 `latitude`  varchar(255),
 `location`  varchar(255),
 `residence_city` varchar(255),
 `residence_zip` varchar(255),
 `objectid` varchar(255),
 `data_source_url` varchar(255),
 `commissioner_district`  varchar(255),
 `md5_hash` varchar(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', case_number, CAST(incident_date as CHAR), CAST(death_date as CHAR), age, gender,  race, latino, manner_of_death, primary_cause, primary_cause_line_a, primary_cause_line_b, primary_cause_line_c, secondary_cause, gun_related, opioid_related, cold_related, heat_related, incident_address, incident_city, incident_zipcode, longitude,residence_city,residence_zip,objectid,commissioner_district,latitude,location))) STORED,
 `run_id`    int,
 `deleted`            tinyint              DEFAULT 0
 `scrape_frequency`   varchar(255)         DEFAULT 'Daily',
 `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
 `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
 `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
