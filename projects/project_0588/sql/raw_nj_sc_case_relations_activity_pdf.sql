use us_court_cases;
CREATE TABLE `raw_nj_sc_case_relations_activity_pdf`
(
  `id`                   BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `case_activities_md5`  VARCHAR(255),
  `case_pdf_on_aws_md5`  VARCHAR(255),

  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Nj Courts',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  INDEX `md5` (`md5_hash`),
  INDEX `deleted` (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Bhawna Pahadiya';
