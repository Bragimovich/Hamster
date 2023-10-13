CREATE TABLE `pa_bccc_case_judgment`(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_id`               VARCHAR(255) null,
  `court_id` 		          BIGINT DEFAULT 74,
  `complaint_id`		      VARCHAR(255) null,
  `party_name`		        VARCHAR(255) null,
  `fee_amount`            VARCHAR(255) null,
  `judgment_amount`	      VARCHAR(255) null,
  `requested_amount`	    VARCHAR(255) null,
  `case_type`	            VARCHAR(255) null,
  `judgment_date`         DATE null,
  `data_source_url`       varchar(500) null,
  `created_by`            VARCHAR(255)       DEFAULT 'M Musa',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                BIGINT(20) null,
  `touched_run_id`         BIGINT(20),
  `deleted`               BOOLEAN            DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by M Musa 649';
