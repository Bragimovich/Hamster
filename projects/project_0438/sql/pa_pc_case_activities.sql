CREATE TABLE `pa_pc_case_activities`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`              SMALLINT           DEFAULT NULL,
  `case_id`               VARCHAR(100)       DEFAULT NULL,

  `activity_date`         DATETIME           DEFAULT NULL,
  `activity_decs`         VARCHAR(1000)      DEFAULT NULL,
  `activity_type`         VARCHAR(255)       DEFAULT NULL,
  `activity_pdf`          VARCHAR(255)       DEFAULT NULL,

  `deleted`               TINYINT(1)         DEFAULT 0,
  `run_id`                BIGINT(20)         DEFAULT NULL,
  `data_source_url`       VARCHAR(255)       DEFAULT NULL,
  `md5_hash`              VARCHAR(32)        DEFAULT NULL,
  `created_by`            VARCHAR(20)        DEFAULT 'Eldar Eminov',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5_hash` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
