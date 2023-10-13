CREATE TABLE `il_mchenry__arrestee_aliases`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id`     BIGINT(20),
  `full_name`       VARCHAR(500) DEFAULT NULL,
  `first_name`      VARCHAR(255) DEFAULT NULL,
  `middle_name`     VARCHAR(50)  DEFAULT NULL,
  `last_name`       VARCHAR(255) DEFAULT NULL,
  `suffix`          VARCHAR(255) DEFAULT NULL,
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
