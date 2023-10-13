create table `tx_hcc_case_activities`
(
  `id`                          INT auto_increment   primary key,
  `court_id`                    int               DEFAULT 88,
  `case_id`                     VARCHAR (255),
  `activity_date`               DATE              DEFAULT NULL,
  `activity_decs`               text,
  `activity_type`               VARCHAR (255),
  `activity_pdf`                VARCHAR (255),
  `run_id`                      int,
  `deleted`                     BOOLEAN            DEFAULT 0,
  `touched_run_id`              int,
  `md5_hash`                    VARCHAR(255)       DEFAULT NULL,
  `data_source_url`             VARCHAR (255)      DEFAULT "https://www.cclerk.hctx.net/applications/websearch/CourtSearch.aspx?CaseType=Civil",
  `created_by`                  VARCHAR (255)      DEFAULT 'Azeem',
  `created_at`                  DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
