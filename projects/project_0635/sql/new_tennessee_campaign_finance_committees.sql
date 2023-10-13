CREATE TABLE `new_tennessee_campaign_finance_commitees`
(
  `id`                                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `committee_name`                    VARCHAR(255) NULL,
  `address`                           VARCHAR(255) NULL,
  `phone`                             VARCHAR(255) NULL,
  `email`                             VARCHAR(255) NULL,
  `city_state_zip`                    VARCHAR(255) NULL,
  `treasurer_name`                    VARCHAR(255)         NULL,
  `treasurer_address`                 VARCHAR(255) NULL,
  `treasurer_city_state_zip`          VARCHAR(255) NULL,
  `treasurer_phone`                   VARCHAR(255) NULL,
  `treasurer_email`                   VARCHAR(255) NULL,
  `party_affiliation`                 VARCHAR(255)         NULL,
  `office_sought`                     VARCHAR(255) NULL,
  `report_list_link`                  VARCHAR(255)         NULL,
  `scrape_frequency`                  VARCHAR(255) DEFAULT 'Monthly',
  `data_source_url`                   VARCHAR(255) DEFAULT 'https://apps.tn.gov/tncamp/public/cpresults.htm',
  `created_by`                        VARCHAR(255) DEFAULT 'Aqeel',
  `created_at`                        DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                            BIGINT(20),
  `touched_run_id`                    BIGINT,
  `deleted`                           BOOLEAN            DEFAULT 0,
  `md5_hash`                          VARCHAR(100) GENERATED ALWAYS AS (md5(CONCAT_WS('',committee_name, address, phone, email, city_state_zip, treasurer_name, treasurer_city_state_zip, treasurer_phone, treasurer_email, party_affiliation, office_sought))) STORED,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
comment = 'created';
