CREATE TABLE `washington_state_campaign_expenditures_csv`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),

  `report_number`     BIGINT,
  `origin`            VARCHAR(50),
  `committee_id`     BIGINT,
  `filer_id`           VARCHAR(50),
  `type`           VARCHAR(50),
  `filer_name`           VARCHAR(150),
  `office`           VARCHAR(50),
  `legislative_district`           VARCHAR(50),
  `position`           VARCHAR(150),
  `party`           VARCHAR(50),
  `ballot_number`           VARCHAR(50),
  `for_or_against`           VARCHAR(50),
  `jurisdiction`           VARCHAR(100),
  `jurisdiction_county`           VARCHAR(50),
  `jurisdiction_type`           VARCHAR(50),
  `election_year`           INT,
  `amount`                 DECIMAL(10,2),
  `itemized_or_non_itemized`           VARCHAR(50),
  `expenditure_date`              DATE,
  `description`           VARCHAR(150),
  `code`                 VARCHAR(50),
  `recipient_name`     VARCHAR(100),
  `recipient_address`     VARCHAR(150),
  `recipient_city`      VARCHAR(50),
  `recipient_state`      VARCHAR(10),
  `recipient_zip`            INT,
  `url`                     VARCHAR(150),
  `recipient_location`         VARCHAR(150),


  `data_source_url` VARCHAR(255)       DEFAULT 'https://data.wa.gov/Politics/Expenditures-by-Candidates-and-Political-Committee/tijg-9zyp',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `deleted`         BOOLEAN,
  `touched_run_id`  BIGINT,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
