CREATE TABLE `deleware_arrestees`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `full_name`       VARCHAR(255),
  `first_name`      VARCHAR(255),
  `middle_name`     VARCHAR(255),
  `last_name`       VARCHAR(255),
  `suffix`          VARCHAR(255),
  `birthdate`       VARCHAR(255),
  `age`             VARCHAR(255),
  `race`            VARCHAR(255),
  `sex`             VARCHAR(255),
  `height`          VARCHAR(255),
  `weight`          VARCHAR(255),
  `eye_color`       VARCHAR(255),
  `hair_color`      VARCHAR(255),
  `skin_color`      VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Abdul Wahab',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
