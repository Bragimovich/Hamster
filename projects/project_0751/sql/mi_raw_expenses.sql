CREATE TABLE `MI_RAW_expenses`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`            BIGINT(20),
  `doc_seq_no`        INT,
  `expenditure_type`  VARCHAR(255),
  `gub_account_type`  VARCHAR(255),
  `gub_elec_type`     VARCHAR(255),
  `page_no`           INT,
  `expense_id`        INT,
  `detail_id`         INT,
  `doc_stmnt_year`    INT,
  `doc_type_desc`     VARCHAR(255),
  `com_legal_name`    VARCHAR(255),
  `common_name`       VARCHAR(255),
  `cfr_com_id`        INT,
  `com_type`          VARCHAR(255),
  `schedule_desc`     VARCHAR(255),
  `exp_desc`          VARCHAR(255),
  `purpose`           VARCHAR(255),
  `extra_desc`        VARCHAR(255),
  `f_name`            VARCHAR(255),
  `lname_or_org`      VARCHAR(255),
  `address`           VARCHAR(255),
  `city`              VARCHAR(255),
  `state`             VARCHAR(255),
  `zip`               VARCHAR(255),
  `exp_date`          DATE,
  `amount`            DECIMAL(10,2),
  `state_loc`         VARCHAR(255),
  `supp_opp`          VARCHAR(255),
  `can_or_ballot`     VARCHAR(255),
  `county`            VARCHAR(255),
  `debt_payment`      VARCHAR(255),
  `vend_name`         VARCHAR(255),
  `vend_city`         VARCHAR(255),
  `vend_state`        VARCHAR(255),
  `vend_zip`          VARCHAR(255),
  `gotv_ink_ind`      VARCHAR(255),
  `fundraiser`        VARCHAR(255),
  `data_source_url`   VARCHAR(255),
  `created_by`        VARCHAR(255)      DEFAULT 'Hatri',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `md5_hash` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Hatri';