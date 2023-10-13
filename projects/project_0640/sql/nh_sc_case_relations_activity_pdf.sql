CREATE TABLE `nh_sc_case_relations_activity_pdf`
(
  `id`                    INT AUTO_INCREMENT PRIMARY KEY,
  `run_id`                INT,
  `case_activities_md5`   VARCHAR(255),
  `case_pdf_on_aws_md5`   VARCHAR(255),
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN           DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Hatri';
