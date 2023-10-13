CREATE TABLE `congress_nomination_persons`
(
	`id`              			BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
	`nom_id`          			VARCHAR(255),
  `congress_number`       INT(20),
  `full_name`          		VARCHAR(255),
  `dept_id`          			BIGINT(20),
  `nom_desc`          		TEXT,
  `date_received`         DATE,
  `committee_id`          BIGINT(20),
  `data_source_url` 			TEXT,
  `md5_hash`        			VARCHAR(255),
	`created_by`      			VARCHAR(255)       DEFAULT 'Victor Linnik',
	`created_at`      			DATETIME           DEFAULT CURRENT_TIMESTAMP,
	`updated_at`      			TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #498';

CREATE TABLE `congress_nomination_actions`
(
	`nom_id`          			VARCHAR(255),
  `action_date`          	DATE,
  `action_text`          	TEXT,
  `latest_action`        	BOOLEAN,
  `urls_in_action`       	VARCHAR(255),
  `md5_hash`        			VARCHAR(255),
  `created_by`      			VARCHAR(255)       DEFAULT 'Victor Linnik',
	`created_at`      			DATETIME           DEFAULT CURRENT_TIMESTAMP,
	`updated_at`      			TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #498';
  
 CREATE TABLE `congress_nomination_departments`
(
	`id`              			BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `dept_name`          		VARCHAR(255),
  `created_by`      			VARCHAR(255)       DEFAULT 'Victor Linnik',
	`created_at`      			DATETIME           DEFAULT CURRENT_TIMESTAMP,
	`updated_at`      			TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #498';
  
   CREATE TABLE `congress_nomination_committee`
(
	`id`              			BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `comm_name`          		VARCHAR(255),
  `created_by`      			VARCHAR(255)       DEFAULT 'Victor Linnik',
	`created_at`      			DATETIME           DEFAULT CURRENT_TIMESTAMP,
	`updated_at`      			TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #498';

CREATE TABLE `congress_nomination_nominees`
(
	`nom_id`          			VARCHAR(255),
  `nominee_status`        VARCHAR(255),
  `nominee_text`          TEXT,
  `person_name`          	VARCHAR(255),
  `md5_hash`        			VARCHAR(255),
  `created_by`      			VARCHAR(255)       DEFAULT 'Victor Linnik',
	`created_at`      			DATETIME           DEFAULT CURRENT_TIMESTAMP,
	`updated_at`      			TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Victor Linnik, Task #498';
  