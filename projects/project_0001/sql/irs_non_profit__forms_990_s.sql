create table woke_project.irs_non_profit__forms_990_s
(
    `id`                       BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `return_link_id`           VARCHAR(8)         DEFAULT NULL,
    `filing_type`              VARCHAR(1)         DEFAULT NULL,
    `ein`                      VARCHAR(9)         DEFAULT NULL,
    `tax_period`               VARCHAR(6)         DEFAULT NULL,
    `return_fill_date`         DATE               DEFAULT NULL,
    `org_name`                 VARCHAR(300)       DEFAULT NULL,
    `return_type`              VARCHAR(10)        DEFAULT NULL,
    `object_id`                varchar(100)       DEFAULT NULL,

    `data_source_url`          VARCHAR(255)       DEFAULT NULL,
    `md5_hash`                 VARCHAR(32)        DEFAULT NULL,
    `run_id`                   BIGINT(20),
    `deleted`                  TINYINT(1)         DEFAULT 0,
    `created_by`               VARCHAR(20)        DEFAULT 'Eldar Eminov',
    `created_at`               DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX `ein` (`ein`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;