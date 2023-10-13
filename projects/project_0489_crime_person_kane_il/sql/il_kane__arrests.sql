CREATE TABLE crime_perps__step_1.il_kane__arrests
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    `arrestee_id`      BIGINT(20),
    `status`          VARCHAR(255),
    `arrest_date`     DATE,
    `booking_date`    DATE,
    `booking_agency`            VARCHAR(255),
    `booking_agency_type`       VARCHAR(255),
    `booking_agency_subtype`    VARCHAR(255),
    `booking_number`       VARCHAR(255),
    `data_source_url` TEXT,
    `created_by`      VARCHAR(255)      DEFAULT 'Maxim G',
    `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`  BIGINT,
    `deleted`         BOOLEAN           DEFAULT 0,
    `md5_hash`        VARCHAR(255),
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;