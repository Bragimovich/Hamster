CREATE TABLE `wi_campaign_finance_contributors`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `transaction_date`         DATE,
  `filing_period_name`       VARCHAR(255),
  `contributor_name`         VARCHAR(255),
  `contribution_amount`      FLOAT,
  `address_line1`            VARCHAR(255),
  `address_line2`            VARCHAR(255),
  `city`                     VARCHAR(255),
  `state`                    VARCHAR(255),
  `zip`                      VARCHAR(255),
  `occupation_title`         VARCHAR(255),
  `employer_name`            VARCHAR(255),
  `employer_address`         VARCHAR(255),
  `contributor_type`         VARCHAR(255),
  `receiving_committee_name` VARCHAR(255),
  `committee_id`             VARCHAR(255),
  `conduit`                  VARCHAR(255),
  `office_branch`            VARCHAR(255),
  `comment`                  VARCHAR(512),
  `hr_reports`            VARCHAR(255),
  `segregated_fund_flag`     BOOLEAN,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by agegic';

CREATE TABLE `wi_campaign_finance_expenditures`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `registrant_name`        VARCHAR(255),
  `committee_id`           VARCHAR(255),
  `office_branch`          VARCHAR(255),
  `payee_name`             VARCHAR(255),
  `transaction_date`       DATE,
  `communication_date`     DATE,
  `expense_purpose`        VARCHAR(255),
  `expense_category`       VARCHAR(255),
  `filing_period_name`     VARCHAR(255),
  `filing_fee_name`        VARCHAR(255),
  `recount_name`           VARCHAR(255),
  `recall_name`            VARCHAR(255),
  `referendum_name`        VARCHAR(255),
  `ind_exp_candidate_name` VARCHAR(255),
  `support_oppose`         VARCHAR(255),
  `amount`                 FLOAT,
  `comment`                VARCHAR(512),
  `hr_reports`          VARCHAR(255),
  `payee_address_line1`    VARCHAR(255),
  `payee_address_line2`    VARCHAR(255),
  `payee_city`             VARCHAR(255),
  `payee_state`            VARCHAR(255),
  `payee_zip`              VARCHAR(255),
  `segregated_fund_flag`   BOOLEAN,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by agegic';

CREATE TABLE `wi_campaign_finance_committees`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `committee_id`          VARCHAR(255),
  `candidate_full_name`   VARCHAR(255),
  `candidate_first_name`  VARCHAR(255),
  `candidate_last_name`   VARCHAR(255),
  `candidate_middle_name` VARCHAR(255),
  `party_affillation`     VARCHAR(255),
  `office_branch`         VARCHAR(255),
  `candidate_address`     VARCHAR(255),
  `candidate_city`        VARCHAR(255),
  `candidate_state`       VARCHAR(255),
  `candidate_zip`         VARCHAR(255),
  `candidate_phone`       VARCHAR(255),
  `election_date`         DATE,
  `candidate_email`       VARCHAR(255),
  `committee_name`        VARCHAR(255),
  `acronym`               VARCHAR(255),
  `committee_type`        VARCHAR(255),
  `committee_sub_type`    VARCHAR(255),
  `committee_address`     VARCHAR(255),
  `committee_city`        VARCHAR(255),
  `committee_state`       VARCHAR(255),
  `committee_zip`         VARCHAR(255),
  `committee_email`       VARCHAR(255),
  `committee_phone`       VARCHAR(255),
  `segregated_fund_name`  VARCHAR(255),
  `leader_of_legislative` VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by agegic';