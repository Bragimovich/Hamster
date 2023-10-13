CREATE TABLE `ca_kcsc_case_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',

  `created_by`      VARCHAR(255)       DEFAULT 'Asim Saeed',
  `download_status` VARCHAR(255)       DEFAULT 'processing',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `search_index` (`status`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Asim Saeed, Task #0644';