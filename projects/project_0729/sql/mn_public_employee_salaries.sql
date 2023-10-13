CREATE TABLE `mn_public_employee_salaries` 
(
    `id`                 INT AUTO_INCREMENT PRIMARY KEY,
    `run_id`             BIGINT(20),
    `temporary_id`       BIGINT(20) NOT NULL,
    `regular_wages`      INT DEFAULT NULL,
    `overtime_wages`     INT DEFAULT NULL,
    `other_wages`        INT DEFAULT NULL,
    `total_wages`        INT DEFAULT NULL,
    `data_source_url`    VARCHAR(256) DEFAULT NULL,
    `created_by`         VARCHAR(255) DEFAULT 'Afia',
    `created_at`         DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`     BIGINT    NOT NULL,
    `md5_hash`           VARCHAR(100) DEFAULT NULL,
    UNIQUE KEY `unique_data` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Afia, Task #729';
