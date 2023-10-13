CREATE TABLE `id_agency_heads`
(
    `id`                   BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`               BIGINT(20),
    `touched_run_id`       BIGINT(20),

    `name`                 VARCHAR(100)          DEFAULT NULL,
    `job_title`            VARCHAR(100)          DEFAULT NULL,
    `agency_code`          INT                   DEFAULT NULL,
    `agency_name`          VARCHAR(100)          DEFAULT NULL,
    `annual_salary`        DECIMAL(13,2)         DEFAULT NULL,
    `date_of_loads`        VARCHAR(100)          DEFAULT NULL,

    `deleted`              BOOLEAN               DEFAULT 0,
    `md5_hash`             VARCHAR(32)           DEFAULT NULL,
    `created_by`           VARCHAR(20)           DEFAULT 'Farzpal Singh',
    `created_at`           DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `md5_hash_index` (`md5_hash`),
    UNIQUE KEY `md5_hash_unique` (`md5_hash`),
    INDEX `deleted_index` (`deleted`)

) DEFAULT CHARSET = `utf8mb4`
 COLLATE = utf8mb4_unicode_520_ci;
COMMENT = 'Created by Farzpal Singh, Task #728';
