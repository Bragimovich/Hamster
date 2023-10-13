CREATE TABLE `washington_state_candidates_csv`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),

  `committee_id`     BIGINT,
  `candidate_id`     BIGINT,
  `filer_id`           VARCHAR(50),
  `filer_type`           VARCHAR(50),
  `receipt_date`              DATE,
  `election_year`           INT,
  `filer_name`           VARCHAR(150),

  `committee_acronym`   VARCHAR(255),
  `committee_address`   VARCHAR(255),
  `committee_city`      VARCHAR(150),
  `committee_county`    VARCHAR(150),
  `committee_state`     VARCHAR(50),
  `committee_zip`        INT,
  `committee_email`   VARCHAR(255),
  `candidate_email`   VARCHAR(255),
  `candidate_committee_phone`   VARCHAR(255),

  `office`           VARCHAR(50),
  `office_code`        INT,
  `jurisdiction`           VARCHAR(100),
  `jurisdiction_code`        INT,
  `jurisdiction_county`           VARCHAR(50),
  `jurisdiction_type`           VARCHAR(50),



  `committee_category`           VARCHAR(255),
  `political_committee_type`           VARCHAR(255),
  `bonafide_committee`           VARCHAR(255),
  `bonafide_type`           VARCHAR(150),
  `position`           VARCHAR(150),
  `party_code`        INT,
  `party`           VARCHAR(50),
  `election_date`              DATE,
  `exempt_nonexempt`           VARCHAR(150),
  `ballot_committee`           VARCHAR(255),
  `ballot_number`           VARCHAR(50),
  `for_or_against`           VARCHAR(255),
  `other_pac`           VARCHAR(255),





  `treasurer_name`           VARCHAR(255),
  `treasurer_address`           VARCHAR(255),
  `treasurer_city`           VARCHAR(255),
  `treasurer_state`           VARCHAR(255),
  `treasurer_zip`               BIGINT,
  `treasurer_phone`           VARCHAR(255),

  `url`                     VARCHAR(150),


  `data_source_url` VARCHAR(255)       DEFAULT 'https://data.wa.gov/Politics/Candidate-and-Committee-Registrations/iz23-7xxj',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `deleted`         BOOLEAN,
  `touched_run_id`  BIGINT,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `candidate_id` (`candidate_id`),
  INDEX `committee_id` (`committee_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
