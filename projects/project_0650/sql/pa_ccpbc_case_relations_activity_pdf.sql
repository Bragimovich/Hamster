CREATE TABLE `pa_ccpbc_case_relations_activity_pdf`
(
  `id`                          BIGINT(20)        AUTO_INCREMENT PRIMARY KEY,
  `run_id`                      BIGINT(20),
  `court_id`                    INT               DEFAULT 102,
  `case_activities_md5`         VARCHAR(255),
  `case_pdf_on_aws_md5`         VARCHAR(255),
  `created_by`                  VARCHAR(255)      DEFAULT 'Raza',
  `created_at`                  DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`                     BOOLEAN           DEFAULT 0,
  `touched_run_id`              BIGINT(20),
  UNIQUE KEY `unique` (`case_activities_md5`, `case_pdf_on_aws_md5`),
  INDEX `run_id` (`run_id`),
  INDEX `court_id,` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Raza Aslam, Task #650';
