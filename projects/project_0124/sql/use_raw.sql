CREATE TABLE `Illinois`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
   `name`           VARCHAR(255),
   `former_names`   VARCHAR(255),
   `law_firm_name`  VARCHAR(255),
   `law_firm_address` VARCHAR(255),
   `law_firm_city_state_zip` VARCHAR(255),
   `phone` VARCHAR(255),
   `date_admitted` datetime,
   `registration_status_raw` VARCHAR(1024),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `Illinois_runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT 'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `status_idx` (`status`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;