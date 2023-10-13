CREATE TABLE `sba_list_scorecard_raw_person`  
( 
   `id`                             int auto_increment  primary key, 
   `run_id`                         BIGINT(20),
   `person_name`                    VARCHAR(256)         DEFAULT NULL, 
   `party`                          VARCHAR(256)         DEFAULT NULL, 
   `state`                          VARCHAR(256)         DEFAULT NULL, 
   `district`                       VARCHAR(256)         DEFAULT NULL, 
   `rating`                         VARCHAR(256)         DEFAULT NULL, 
   `senate_or_house`                VARCHAR(256)         DEFAULT NULL, 
   `position`                       VARCHAR(256)         DEFAULT NULL, 
   `data_source_url`                VARCHAR(256)         DEFAULT NULL,
   `deleted`                        BOOLEAN              DEFAULT 0, 
   `touched_run_id`                 int                  not null,
   `created_by`                     VARCHAR(255)         DEFAULT 'Afia', 
   `created_at`                     DATETIME             DEFAULT CURRENT_TIMESTAMP, 
   `updated_at`                     TIMESTAMP            DEFAULT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, 
   `md5_hash`                       VARCHAR(100)         GENERATED ALWAYS AS (md5(CONCAT_WS('', person_name, party, state, district, rating, senate_or_house, position))) STORED UNIQUE KEY,
   UNIQUE KEY `unique_data` (`md5_hash`),
   INDEX `party` (`party`),
   INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci,
COMMENT = 'Created by Afia, Task #753';
