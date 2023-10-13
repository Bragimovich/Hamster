CREATE TABLE `fl_hc_13jcc_case_activities`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`                  INT,
  `case_id`                   VARCHAR (255),
  `activity_date`             DATE,
  `activity_decs`             MEDIUMTEXT,
  `activity_type`             VARCHAR (255),
  `activity_pdf`              VARCHAR (255),
  `created_at`                DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by`                VARCHAR(255)      DEFAULT 'Usman',
  `data_source_url`           VARCHAR(255)      DEFAULT 'https://hover.hillsclerk.com/html/case/caseSearch.html', 
  `scrape_frequency`          VARCHAR(255) DEFAULT 'Weekly',
  `run_id`                    INT,
  `deleted`                   BOOLEAN DEFAULT '0',
  `md5_hash`                  varchar(255),
  `activity_pdf`              VARCHAR(255),
  `touched_run_id`            int not null,
  UNIQUE KEY md5 (`md5_hash`),
  INDEX court_id_idx (`court_id`),
  INDEX deleted_idx (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Muhammad Usman, Task #0654';
