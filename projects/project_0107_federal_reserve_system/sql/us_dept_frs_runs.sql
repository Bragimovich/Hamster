CREATE TABLE `us_dept_frs_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status` VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Eldar M.',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   INDEX `status_idx` (`status`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

ALTER TABLE us_dept_frs_runs ALTER COLUMN created_by SET DEFAULT 'Oleksii Kuts';
ALTER TABLE us_dept_frs_runs COMMENT 'Runs for data from federalreserve.gov, Created by Eldar M., Updated by Oleksii Kuts, Task #107';
