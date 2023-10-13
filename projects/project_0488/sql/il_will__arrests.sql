CREATE TABLE `il_will__arrests`
(
  `id`                         BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id`                BIGINT(20),
  `arrest_date`                DATE,
  `booking_date`               DATE,
  `booking_agency`             VARCHAR(255) DEFAULT NULL,
  `booking_agency_type`        VARCHAR(255) DEFAULT NULL,
  `booking_agency_subtype`     VARCHAR(255) DEFAULT NULL,
  `booking_number`             VARCHAR(255) DEFAULT NULL,
  `status`                     VARCHAR(255) DEFAULT NULL,
  `data_source_url`            VARCHAR(255) DEFAULT NULL,
  `created_by`                 VARCHAR(255)       DEFAULT 'Andrey Tereshchenko',
  `created_at`                 DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                     BIGINT DEFAULT NULL,
  `touched_run_id`             BIGINT DEFAULT NULL,
  `deleted`                    BOOLEAN            DEFAULT 0,
  `md5_hash`                   VARCHAR(255),
  INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
