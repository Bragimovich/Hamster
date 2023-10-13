CREATE TABLE `MI_RAW_committees`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  `bureau_committee_id`   INT,
  `committee_type`        VARCHAR(55),
  `committee_group`       VARCHAR(55),
  `committee_status`      VARCHAR(55),
  `committee_name`        VARCHAR(75),
  `mailing_address`       VARCHAR(75),
  `mailing_city`          VARCHAR(55),
  `mailing_state`         VARCHAR(55),
  `mailing_zipcode`       VARCHAR(55),
  `phone`                 VARCHAR(55),
  `office_sought`         VARCHAR(100),
  `district_sought`       VARCHAR(100),
  `political_party`       VARCHAR(55),
  `sof_o_received_date`   DATE,
  `committee_formed_date` DATE,
  `data_source_url`       VARCHAR(255)      DEFAULT 'https://drive.google.com/drive/folders/10MEskbZAyK6cSAA9GLTb5mInEub39BeC',
  `created_by`            VARCHAR(255)      DEFAULT 'Hatri',
  `created_at`            DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN           DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `md5_hash` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Hatri';
