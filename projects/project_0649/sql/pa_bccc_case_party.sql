CREATE TABLE `pa_bccc_case_party`(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_id`               VARCHAR(255),
  `court_id` 		          BIGINT DEFAULT 74,
  `is_lawyer`             boolean,
  `party_name`            VARCHAR(256),
  `party_type`            VARCHAR(256),
  `law_firm`              VARCHAR(256),
  `party_address`         VARCHAR(256),
  `party_city`			      VARCHAR(256),
  `party_state`			      VARCHAR(256),
  `party_zip`			        VARCHAR(256),
  `party_description`     Varchar(256),
  `run_id`                BIGINT(20),
  `touched_run_id`          BIGINT(20),
  `deleted`               BOOLEAN            DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  `data_source_url`       TEXT,
  `created_by`            VARCHAR(255)       DEFAULT 'M Musa',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by M Musa 649';
