CREATE TABLE `deleware_arrestee_aliases`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`              BIGINT(20),
  `arrestees_id`        BIGINT(20),
  `alias_full_name`     VARCHAR(255),
  `alias_first_name`    VARCHAR(255),
  `alias_middle_name`   VARCHAR(255),
  `alias_last_name`     VARCHAR(255),
  `alias_suffix`        VARCHAR(255),
  `data_source_url`     TEXT,
  `created_by`          VARCHAR(255)      DEFAULT 'Abdul Wahab',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
