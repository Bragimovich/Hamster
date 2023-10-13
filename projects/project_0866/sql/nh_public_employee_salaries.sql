CREATE TABLE IF NOT EXISTS `state_salaries__raw`.`nh_public_employee_salaries`
(
  `id`                         BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `year`                       INT NULL DEFAULT NULL,
  `employee_last_name`         VARCHAR(255) NULL DEFAULT NULL,
  `employee_first_name`        VARCHAR(255) NULL DEFAULT NULL,
  `employee_middle_initial`    VARCHAR(255) NULL DEFAULT NULL,
  `title`                      VARCHAR(255) NULL DEFAULT NULL,
  `pay_category`               VARCHAR(255) NULL DEFAULT NULL,
  `agency`                     VARCHAR(255) NULL DEFAULT NULL,
  `annual_salary`              VARCHAR(255) NULL DEFAULT NULL,
  `internal_employee_id`       BIGINT(20) NULL DEFAULT NULL,
  `status`                     VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url`            TEXT NULL DEFAULT NULL,
  `created_by`                 VARCHAR(255) NULL DEFAULT 'Abdul Wahab',
  `created_at`                 DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                     BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`             BIGINT(20) NULL DEFAULT NULL,
  `deleted`                    TINYINT(1) NULL DEFAULT '0',
  `md5_hash`                   VARCHAR(255) NULL DEFAULT NULL,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
)
DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci ;
