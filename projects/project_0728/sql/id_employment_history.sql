CREATE TABLE `id_employment_history`
(
    `id`                            BIGINT(20)  AUTO_INCREMENT  PRIMARY KEY,
    `run_id`                        BIGINT(20),
    `touched_run_id`                BIGINT(20),

    `employee_name`                 VARCHAR(100)          DEFAULT NULL,
    `job_title`                     VARCHAR(100)          DEFAULT NULL,
    `agency_name`                   VARCHAR(100)          DEFAULT NULL,
    `pay_rate`                      DECIMAL(13,2)        DEFAULT NULL,
    `pay_basis`                     VARCHAR(100)          DEFAULT NULL,
    `full_or_part_status`           VARCHAR(100)          DEFAULT NULL,
    `prior_record`                  VARCHAR(100)          DEFAULT NULL,
    `status`                        VARCHAR(100)          DEFAULT NULL,
    `hire_date`                     DATETIME              DEFAULT NULL,
    `appointment_type`              VARCHAR(100)          DEFAULT NULL,
    `seperation_date`               VARCHAR(100)          DEFAULT NULL,
    `months_at_agency`              VARCHAR(100)          DEFAULT NULL,

    `deleted`                       BOOLEAN               DEFAULT 0,
    `md5_hash`                      VARCHAR(32)           DEFAULT NULL,
    `created_by`                    VARCHAR(20)           DEFAULT 'Farzpal Singh',
    `created_at`                    DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                    TIMESTAMP NOT NULL    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `md5_hash_index` (`md5_hash`),
    UNIQUE KEY `md5_hash_unique` (`md5_hash`),
    INDEX `deleted_index` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci ;
COMMENT = 'Created by Farzpal Singh, Task #728';
