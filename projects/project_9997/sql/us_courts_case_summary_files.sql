CREATE TABLE `us_courts_case_summary_files`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`         BIGINT(20),
  `case_id`         VARCHAR(255),
  `aws_html_link`   VARCHAR(255),
  `aws_pdf_link`    VARCHAR(255),
  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)       DEFAULT 'Andrey Tereshchenko',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT(1)            DEFAULT 0,
  `is_pacer`        TINYINT(1)            DEFAULT 0
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
