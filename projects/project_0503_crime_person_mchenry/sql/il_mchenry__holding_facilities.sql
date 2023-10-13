CREATE TABLE `il_mchenry__holding_facilities`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrest_id`                 BIGINT(20),
  `facility`                  VARCHAR(255) DEFAULT NULL,
  `facility_type`             VARCHAR(255)  DEFAULT NULL,
  `facility_subtype`          VARCHAR(255) DEFAULT NULL,
  `start_date`                DATE,
  `planned_release_date`      DATE,
  `actual_release_date`       DATE,
  `data_source_url` VARCHAR(255) DEFAULT NULL,
  `created_by`      VARCHAR(255)       DEFAULT 'Dmitry Suschinsky',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT DEFAULT NULL,
  `touched_run_id`  BIGINT DEFAULT NULL,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
