CREATE TABLE `deleware_vehicles`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `arrestee_id`     BIGINT(20),
  `type_vehicles`   VARCHAR(255),
  `make`            VARCHAR(255),
  `model`           VARCHAR(255),
  `color`           VARCHAR(255),
  `registration`    VARCHAR(255),
  `state_id`        BIGINT(20),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Abdul Wahab',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
