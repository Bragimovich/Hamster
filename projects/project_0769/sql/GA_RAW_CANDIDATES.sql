CREATE TABLE `GA_RAW_CANDIDATES`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  # BEGIN scrape 769
  `filer_id`              VARCHAR(255),
  `candidate_full_name`      VARCHAR(255),
  `candidate_address1`       VARCHAR(255),
  `candidate_address2`       VARCHAR(255),
  `candidate_csz`            VARCHAR(255),
  `candidate_phone1`         VARCHAR(255),
  `candidate_phone2`         VARCHAR(255),
  `candidate_party`          VARCHAR(255),
  `candidate_office_sought`  VARCHAR(255),
  `committee_name`           VARCHAR(255),
  `committee_address1`       VARCHAR(255),
  `committee_address2`       VARCHAR(255),
  `committee_csz`            VARCHAR(255),
  `committee_phone1`         VARCHAR(255),
  `committee_phone2`         VARCHAR(255),
  # END
  `data_source_url`       VARCHAR(255)        ,
  `created_by`            VARCHAR(255)        DEFAULT 'Oleksii Kuts',
  `created_at`            DATETIME            DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN             DEFAULT 0,
  `md5_hash`              VARCHAR(32),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'CANDIDATES from media.ethics.ga.gov, Created by Oleksii Kuts, Task #769';
