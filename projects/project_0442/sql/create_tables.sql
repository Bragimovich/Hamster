CREATE TABLE `il_lc_case_runs`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`              VARCHAR(255)       DEFAULT 'processing',
  `created_by`          VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Victor Linnik, Task #442';
    
CREATE TABLE `il_lc_case_activities`(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_id` 		  	      VARCHAR(255),
  `court_id` 		          BIGINT DEFAULT 74,
  `activity_date`         DATE,
  `activity_decs`         mediumtext,
  `activity_type`	        Varchar(255),
  `activity_pdf`	        varchar(255),
  `data_source_url`       TEXT,
  `created_by`            VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                BIGINT(20),
  `touched_run_id`        BIGINT(20),
  `deleted`               BOOLEAN            DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #442';


  CREATE TABLE `il_lc_case_info`(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id` 		          VARCHAR(255) DEFAULT 74,
  `case_name`             VARCHAR(255),
  `case_id`               VARCHAR(255),
  `case_filed_date`       VARCHAR(255),
  `case_description`      TEXT,
  `case_type`             VARCHAR(255),
  `disposition_or_status` VARCHAR(255),
  `status_as_of_date`     VARCHAR(255),
  `judge_name`            VARCHAR(255),
  `data_source_url`       TEXT,
  `created_by`            VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                BIGINT(20),
  `touched_run_id`        BIGINT(20),
  `deleted`               BOOLEAN            DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #442';
  
    CREATE TABLE `il_lc_case_party`(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_id`               VARCHAR(255),
  `court_id` 		          BIGINT DEFAULT 74,
  `is_lawyer`             VARCHAR(256),
  `party_name`            VARCHAR(256),
  `party_type`            VARCHAR(256),
  `party_law_firm`        VARCHAR(256),
  `party_address`         VARCHAR(256),
  `party_city`			      VARCHAR(256),
  `party_state`			      VARCHAR(256),
  `party_zip`			        VARCHAR(256),
  `party_description`     Varchar(256),
  `data_source_url`       TEXT,
  `created_by`            VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                BIGINT(20),
  `touched_run_id`        BIGINT(20),
  `deleted`               BOOLEAN            DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #442';

  CREATE TABLE `il_lc_case_judgment`(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_id`               VARCHAR(255) null,
  `court_id` 		          BIGINT DEFAULT 74,
  `complaint_id`		      VARCHAR(255) null,
  `party_name`		        VARCHAR(255) null,
  `fee_amount`            VARCHAR(255) null,
  `requested_amount`      varchar(255) null,
  `case_type`             varchar(255) null,
  `activity_type`         varchar(511) null,
  `judgment_amount`	      VARCHAR(255) null,
  `judgment_date`         DATE null,
  `data_source_url`       varchar(500) null,
  `created_by`            VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                BIGINT(20) null,
  `touched_run_id`        BIGINT(20) null,
  `deleted`               BOOLEAN            DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #442';
  