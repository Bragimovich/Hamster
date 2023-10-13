CREATE TABLE `pa_sc_case_pdfs_on_aws`
(
  `id`                            BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`                      INTEGER            DEFAULT NULL,
  `case_id`                       VARCHAR(150)       DEFAULT NULL,

  `source_type`                   VARCHAR(10)        DEFAULT NULL,
  `aws_link`                      VARCHAR(255)       DEFAULT NULL,
  `source_link`                   VARCHAR(255)       DEFAULT NULL,
  `md5_hash`                      VARCHAR(32)        DEFAULT NULL,
  `deleted`                       TINYINT(1)         DEFAULT 0,

  `created_by`                    VARCHAR(255)       DEFAULT 'Eldar Eminov',
  `created_at`                    DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`)
  INDEX `case_id` (`case_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
