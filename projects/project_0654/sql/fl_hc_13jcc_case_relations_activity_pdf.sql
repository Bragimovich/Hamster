CREATE TABLE `fl_hc_13jcc_case_relations_activity_pdf`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_activities_md5`       VARCHAR (255),
  `case_pdf_on_aws_md5`       VARCHAR (255),
  `created_at`                DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by`                VARCHAR(255)      DEFAULT 'Usman',
  `court_id`                  INT,
  `touched_run_id`            int not null,
  `deleted`                   BOOLEAN DEFAULT '0',
  INDEX court_id_idx (`court_id`),
  INDEX deleted_idx (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Muhammad Usman, Task #0654';
