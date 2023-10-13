CREATE TABLE `pa_ccpbc_case_activities`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`              BIGINT(20),
  `court_id`            INT              DEFAULT 102,
  `case_id`             VARCHAR(255),
  `activity_date`       DATE,
  `activity_type`       VARCHAR(255),
  `activity_pdf`        VARCHAR(255),
  `file`                VARCHAR(255),
  `activity_decs`       mediumtext,
  `data_source_url`     VARCHAR(255),
  `created_by`          VARCHAR(255)      DEFAULT 'Raza',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`             BOOLEAN           DEFAULT 0,
  `touched_run_id`      BIGINT(20),
  `md5_hash`            VARCHAR (255)     DEFAULT NULL,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #650';
