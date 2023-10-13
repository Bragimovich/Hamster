CREATE TABLE `ut_saac_case_pdfs_on_aws`
( 
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          int,
  `court_id`        int,
  `case_id`         VARCHAR(255) DEFAULT NULL,
  `source_type`     VARCHAR(255),
  `aws_link`        VARCHAR(255) DEFAULT NULL,
  `md5_hash`        VARCHAR(255) DEFAULT NULL,
  `source_link`     VARCHAR(255) DEFAULT NULL,
  `data_source_url` VARCHAR(255) DEFAULT NULL,
  `aws_html_link`   VARCHAR(255) DEFAULT NULL,
  `created_by`      VARCHAR(255)      DEFAULT 'Raza',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  `touched_run_id`  int,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
