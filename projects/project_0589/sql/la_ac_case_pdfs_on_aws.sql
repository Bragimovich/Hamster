CREATE TABLE `la_2c_ac_case_pdfs_on_aws`
( 
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          int,
  `court_id`        int,
  `case_id`         VARCHAR(255) DEFAULT NULL,
  `source_type`     VARCHAR(255),
  `aws_link`        VARCHAR(255) DEFAULT NULL,
  `source_link`     VARCHAR(255) DEFAULT NULL,
  `created_by`      VARCHAR(255)      DEFAULT 'Tauseeq',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  `touched_run_id`          int,
  `md5_hash` varchar(100),
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `deleted` (`deleted`),
  INDEX `court_id` (`court_id`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
