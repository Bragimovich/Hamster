CREATE TABLE `pa_sc_case_info`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`              SMALLINT           DEFAULT NULL,
  `case_id`               VARCHAR(100)       DEFAULT NULL,

  `case_name`             VARCHAR(200)       DEFAULT NULL,
  `case_filed_date`       DATETIME           DEFAULT NULL,
  `case_type`             VARCHAR(2000)      DEFAULT NULL,
  `case_description`      VARCHAR(6000)      DEFAULT NULL,
  `disposition_or_status` VARCHAR(10)        DEFAULT NULL,
  `status_as_of_date`     VARCHAR(100)       DEFAULT NULL,
  `judge_name`            VARCHAR(100)       DEFAULT NULL,
  `lower_court_id`        SMALLINT           DEFAULT NULL,
  `lower_case_id`         VARCHAR(1000)      DEFAULT NULL,

  `data_source_url`       VARCHAR(255)       DEFAULT NULL,
  `md5_hash`              VARCHAR(32)        DEFAULT NULL,
  `run_id`                BIGINT(20),
  `touched_run_id`        BIGINT(20),
  `deleted`               TINYINT(1)         DEFAULT 0,
  `created_by`            VARCHAR(20)        DEFAULT 'Eldar Eminov',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`)
  INDEX `court_id` (`court_id`)
  INDEX `case_id` (`case_id`)
  INDEX `deleted` (`deleted`)
  INDEX `run_id` (`run_id`)
  INDEX `touched_run_id` (`touched_run_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
