CREATE TABLE `fl_hc_13jcc_case_info`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`                  INT,
  `case_id`                   VARCHAR (255),
  `case_name`                 TEXT,
  `case_filed_date`           DATE,
  `case_type`                 VARCHAR (255),
  `case_description`          VARCHAR (255),
  `disposition_or_status`     VARCHAR (255),
  `status_as_of_date`         VARCHAR (255),
  `judge_name`                VARCHAR (255),
  `created_at`                DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by`                VARCHAR(255)      DEFAULT 'Usman',
  `data_source_url`           VARCHAR(255)      DEFAULT 'https://hover.hillsclerk.com/html/case/caseSearch.html', 
  `scrape_frequency`          VARCHAR(255) DEFAULT 'Weekly',
  `run_id`                    INT,
  `md5_hash`                  varchar(255),
  `touched_run_id`            int not null,
  `deleted`                   BOOLEAN DEFAULT '0',
  UNIQUE KEY md5 (`md5_hash`),
  INDEX court_id_idx (`court_id`),
  INDEX deleted_idx (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Muhammad Usman, Task #0654';
