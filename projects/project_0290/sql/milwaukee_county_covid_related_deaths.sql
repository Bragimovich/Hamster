CREATE TABLE `milwaukee_county_covid_related_deaths`
(
  `id`               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `year`             varchar(255),
  `case_number`      varchar(255), 
  `case_type`        varchar(255), 
  `date_of_event`    date,        
  `date_of_death`    date,         
  `time_of_death`    time,        
  `period`           varchar(10),  
  `age`              int(11),      
  `gender`           varchar(255), 
  `race`             varchar(255), 
  `mode`             varchar(255), 
  `cause_A`          varchar(255), 
  `cause_B`          varchar(255), 
  `cause_other`      varchar(255), 
  `event_address`    varchar(255), 
  `event_city`       varchar(255), 
  `event_state`      varchar(255), 
  `event_zip`        varchar(255),
  `deleted`          boolean          DEFAULT 0, 
  `data_source_url`  varchar(255)     DEFAULT 'https://county.milwaukee.gov/EN/Medical-Examiner/Public-Data',
  `scrape_dev_name`  VARCHAR(255)     DEFAULT 'Adeel',
  `last_scrape_date` date, 
  `next_scrape_date` date,
  `scrape_frequency` VARCHAR(255)     DEFAULT 'Daily',
  `expected_scrape_frequency`     VARCHAR(255)      DEFAULT 'Daily',
  `dataset_name_prefix`           VARCHAR(255)      DEFAULT  'milwaukee_county_covid_related_deaths',
  `scrape_status`          VARCHAR(255)      DEFAULT 'Live',
  `created_at`       DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `pl_gather_task_id`   INT      DEFAULT '175078033'
  `md5_hash`        varchar(100) GENERATED ALWAYS AS (md5(CONCAT_WS('',case_number,case_type,date_of_event,date_of_death,time_of_death,period,age,gender,race,mode,cause_A,cause_B,cause_other,event_address,event_city,event_state,event_zip))) STORED
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Adeel';
