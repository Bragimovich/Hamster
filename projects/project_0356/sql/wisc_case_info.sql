CREATE TABLE `wisc_case_info`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  `court_id`              SMALLINT           DEFAULT NULL,
  `case_id`               VARCHAR(150)       DEFAULT NULL,
  `case_name`             VARCHAR(200)       DEFAULT NULL,
  `case_filed_date`       DATETIME           DEFAULT NULL,
  `case_type`             VARCHAR(150)       DEFAULT NULL,
  `case_description`      VARCHAR(255)       DEFAULT NULL,
  `disposition_or_status` VARCHAR(3)         DEFAULT NULL,
  `status_as_of_date`     VARCHAR(255)       DEFAULT NULL,
  `judge_name`            VARCHAR(255)       DEFAULT NULL,
  `data_source_url`       VARCHAR(100)       DEFAULT NULL,
  `md5_hash`              VARCHAR(32)        DEFAULT NULL,

  `created_by`            VARCHAR(20)        DEFAULT 'Eldar Eminov',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `case_id` (`case_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
