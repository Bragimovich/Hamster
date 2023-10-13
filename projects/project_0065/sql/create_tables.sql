CREATE TABLE `oh_fccc_case_party`
(
    `id`                     BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                 BIGINT(20),
    `court_id`               VARCHAR(255),
    `case_id`                VARCHAR(255),
    `party_name`             MEDIUMTEXT,
    `party_type`             VARCHAR(255),
    `party_address`          VARCHAR(255),
    `party_city`             VARCHAR(255),
    `party_state`            VARCHAR(255),
    `party_zip`              VARCHAR(255),
    `law_firm`               VARCHAR(255),
    `lawyer_additional_data` TEXT,
    `party_description`      TEXT,
    `is_lawyer`              BOOLEAN,
    `data_source_url`        TEXT,
    `scrape_frequency`       VARCHAR(255)       DEFAULT 'daily',
    `created_by`             VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`             DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`         BIGINT,
    `deleted`                BOOLEAN            DEFAULT 0,
    `md5_hash`               VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';

CREATE TABLE `oh_fccc_case_info`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              VARCHAR(255),
    `case_name`             VARCHAR(255),
    `case_id`               VARCHAR(255),
    `case_filed_date`       VARCHAR(255),
    `case_description`      TEXT,
    `case_type`             VARCHAR(255),
    `disposition_or_status` VARCHAR(255),
    `status_as_of_date`     VARCHAR(255),
    `judge_name`            VARCHAR(255),
    `data_source_url`       TEXT,
    `scrape_frequency`      VARCHAR(255)       DEFAULT 'daily',
    `created_by`            VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`        BIGINT,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';

CREATE TABLE `oh_fccc_case_activities`
(
    `id`               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`           BIGINT(20),
    `court_id`         VARCHAR(255),
    `case_id`          VARCHAR(255),
    `activity_date`    VARCHAR(255),
    `activity_decs`    TEXT,
    `activity_type`    VARCHAR(255),
    `activity_pdf`     TEXT,
    `data_source_url`  TEXT,
    `scrape_frequency` VARCHAR(255)       DEFAULT 'daily',
    `created_by`       VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`       DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`   BIGINT,
    `deleted`          BOOLEAN            DEFAULT 0,
    `md5_hash`         VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
  
  CREATE TABLE `oh_fccc_case_judgment`
(
    `id`                     BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                 BIGINT(20),
    `court_id`               VARCHAR(255),
    `case_id`                VARCHAR(255),
    `complaint_id`           VARCHAR(255),
    `party_name`             VARCHAR(255),
    `fee_amount`          	 VARCHAR(255),
    `judgment_amount`        VARCHAR(255),
    `judgment_date`          VARCHAR(255),
    `data_source_url`        TEXT,
    `scrape_frequency`       VARCHAR(255)       DEFAULT 'daily',
    `created_by`             VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`             DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`         BIGINT,
    `deleted`                BOOLEAN            DEFAULT 0,
    `md5_hash`               VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
  
  CREATE TABLE `oh_fccc_case_pdfs_on_aws`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`        INT,
  `case_id`         VARCHAR(255),
  `source_type`     VARCHAR(255),
  `aws_link`        VARCHAR(255),
  `source_link`     VARCHAR(500),
  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
  
  
CREATE TABLE `oh_fccc_case_relations_activity_pdf`
(
  `id`  					        int auto_increment   primary key,
  `case_activities_md5` 	VARCHAR(255),
  `case_pdf_on_aws_md5`  	VARCHAR(255),
  `created_by`      		  VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`      		  DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
  
  CREATE TABLE `oh_fccc_case_relations_info_pdf`
(
  `id`  					        int auto_increment   primary key,
  `case_info_md5` 			  VARCHAR(255),
  `case_pdf_on_aws_md5`  	VARCHAR(255),
  `created_by`      		  VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`      		  DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';

CREATE TABLE `oh_10th_ac_case_info`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              VARCHAR(255),
    `case_name`             VARCHAR(255),
    `case_id`               VARCHAR(255),
    `case_filed_date`       VARCHAR(255),
    `case_description`      TEXT,
    `case_type`             VARCHAR(255),
    `disposition_or_status` VARCHAR(255),
    `status_as_of_date`     VARCHAR(255),
    `judge_name`            VARCHAR(255),
    `lower_court_id`		    int,
	  `lower_case_id`			    VARCHAR(255),
    `data_source_url`       TEXT,
    `scrape_frequency`      VARCHAR(255)       DEFAULT 'daily',
    `created_by`            VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`        BIGINT,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';

    CREATE TABLE `oh_10th_ac_case_additional_info`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              VARCHAR(255),
    `case_id`               VARCHAR(255),
    `lower_court_name`      VARCHAR(255),
    `lower_case_id`      	  VARCHAR(255),
    `lower_judge_name`      VARCHAR(255),
    `lower_judgement_date` 	DATE,
    `lower_link`     		    VARCHAR(255),
    `disposition`           VARCHAR(255),
    `data_source_url`       TEXT,
    `scrape_frequency`      VARCHAR(255)       DEFAULT 'daily',
    `created_by`            VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`        BIGINT,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';


CREATE TABLE `oh_10th_ac_case_party`
(
    `id`                     BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                 BIGINT(20),
    `court_id`               VARCHAR(255),
    `case_id`                VARCHAR(255),
    `party_name`             MEDIUMTEXT,
    `party_type`             VARCHAR(255),
    `party_address`          VARCHAR(255),
    `party_city`             VARCHAR(255),
    `party_state`            VARCHAR(255),
    `party_zip`              VARCHAR(255),
    `party_law_firm`         VARCHAR(255),
    `lawyer_additional_data` TEXT,
    `party_description`      TEXT,
    `is_lawyer`              BOOLEAN,
    `data_source_url`        TEXT,
    `scrape_frequency`       VARCHAR(255)       DEFAULT 'daily',
    `created_by`             VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`             DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`         BIGINT,
    `deleted`                BOOLEAN            DEFAULT 0,
    `md5_hash`               VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
  

CREATE TABLE `oh_10th_ac_case_activities`
(
    `id`               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`           BIGINT(20),
    `court_id`         VARCHAR(255),
    `case_id`          VARCHAR(255),
    `activity_date`    DATE,
    `activity_decs`    mediumtext,
    `activity_type`    VARCHAR(255),
    `file`     		     VARCHAR(255),
    `data_source_url`  TEXT,
    `scrape_frequency` VARCHAR(255)       DEFAULT 'daily',
    `created_by`       VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`       DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`   BIGINT,
    `deleted`          BOOLEAN            DEFAULT 0,
    `md5_hash`         VARCHAR(255),
	UNIQUE KEY        `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
  

  CREATE TABLE `oh_10th_ac_case_pdfs_on_aws`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`        INT,
  `case_id`         VARCHAR(255),
  `source_type`     VARCHAR(255),
  `aws_link`        VARCHAR(255),
  `source_link`     VARCHAR(500),
  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
  
  
CREATE TABLE `oh_10th_ac_case_relations_activity_pdf`
(
  `id`  					int auto_increment   primary key,
  `case_activities_md5` VARCHAR(255),
  `case_pdf_on_aws_md5` VARCHAR(255),
  `created_by`      		VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`      		DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
  
  CREATE TABLE `oh_10th_ac_case_relations_info_pdf`
(
  `id`  					int auto_increment   primary key,
  `case_info_md5` 			VARCHAR(255),
  `case_pdf_on_aws_md5` VARCHAR(255),
  `created_by`      		VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`      		DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';

CREATE TABLE `oh_10th_ac_case_runs`
(
    `id`               BIGINT AUTO_INCREMENT PRIMARY KEY,
    `status`           VARCHAR(255)       DEFAULT 'processing',
    `created_by`       VARCHAR(255)       DEFAULT 'Victor Linnik',
    `created_at`       DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `status_idx` (`status`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #65';
