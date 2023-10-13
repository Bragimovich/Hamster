CREATE TABLE `new_tennessee_campaign_finance_reports`
(
  `id`                                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `committee_id`                      INT          NULL,
  `election`                          VARCHAR(255) NULL,
  `report_name`                       VARCHAR(255) NULL,
  `depreciated`                       Tinyint(1)   NULL,
  `submited_on`                       Date         NULL,
  `report_link`                       VARCHAR(255) NULL,
  `scrape_frequency`                  VARCHAR(255) DEFAULT 'Monthly',
  `data_source_url`                   VARCHAR(255) DEFAULT 'https://apps.tn.gov/tncamp/public/cpresults.htm',
  `created_by`                        VARCHAR(255) DEFAULT 'Aqeel',
  `created_at`                        DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                            BIGINT(20),
  `touched_run_id`                    BIGINT,
  `deleted`                           BOOLEAN            DEFAULT 0,
  `md5_hash`                          VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('',CAST(committee_id as CHAR), election, report_name, Cast(depreciated as CHAR), CAST(submited_on as CHAR), report_link))) STORED,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
comment = 'created';
