CREATE TABLE `wa_pierce_holding_facilities_addresses`
(
  `id`                 BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_address`       VARCHAR(255) NULL DEFAULT NULL,
  `street_address`     VARCHAR(255) NULL DEFAULT NULL,
  `city`               VARCHAR(255) NULL DEFAULT NULL,
  `county`             VARCHAR(255) NULL DEFAULT NULL,
  `state`              VARCHAR(255) NULL DEFAULT NULL,
  `zip`                VARCHAR(255) NULL DEFAULT NULL,
  `lan`                VARCHAR(255) NULL DEFAULT NULL,
  `lon`                VARCHAR(255) NULL DEFAULT NULL,
  `created_by`         VARCHAR(255) NULL DEFAULT 'Raza',
  `created_at`         DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`             BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`     BIGINT(20) NULL DEFAULT NULL,
  `deleted`            TINYINT(1) NULL DEFAULT '0',
  `md5_hash`           VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE INDEX `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Created by Raza Aslam, Task #0863';
