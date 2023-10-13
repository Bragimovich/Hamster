CREATE TABLE `wisc_case_activities`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`              INTEGER            DEFAULT NULL,
  `case_id`               VARCHAR(20)        DEFAULT NULL,
  `run_id`                BIGINT(20),

  `activity_date`         DATETIME           DEFAULT NULL,
  `activity_desc`         MEDIUMTEXT         DEFAULT NULL,
  `activity_type`         VARCHAR(255)       DEFAULT NULL,
  `file`                  VARCHAR(150)       DEFAULT NULL,
  `md5_hash`              VARCHAR(32)        DEFAULT NULL,

  `created_by`            VARCHAR(255)       DEFAULT 'Eldar Eminov',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `file` (`file`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
