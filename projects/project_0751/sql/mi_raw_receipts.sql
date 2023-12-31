CREATE TABLE `MI_RAW_receipts`
(
  `id`                                                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                                              BIGINT(20),
  `doc_seq_no`                                          BIGINT(20),
  `ik_code`                                             VARCHAR(55),
  `gub_account_type`                                    VARCHAR(255),	
  `gub_elec_type`                                       VARCHAR(255),
  `page_no`                                             INT,
  `receipt_id`                                          INT,
  `detail_id`                                           INT,
  `doc_stmnt_year`                                      INT,
  `doc_type_desc`                                       VARCHAR(255),
  `com_legal_name`                                      VARCHAR(255),
  `common_name`                                         VARCHAR(255),
  `cfr_com_id`                                          INT,
  `com_type`                                            VARCHAR(255),
  `can_first_name`                                      VARCHAR(255),
  `can_last_name`                                       VARCHAR(255),
  `contribtype`                                         VARCHAR(255),
  `f_name`                                              VARCHAR(255),
  `l_name_or_org`                                       VARCHAR(255),
  `address`                                             VARCHAR(255),
  `city`                                                VARCHAR(255),
  `state`                                               VARCHAR(255),
  `zip`                                                 VARCHAR(255),
  `occupation`                                          VARCHAR(255),
  `employer`                                            VARCHAR(255),
  `received_date`                                       DATE,
  `amount`                                              DECIMAL(10,2),
  `aggregate`                                           DECIMAL(10,2),
  `extra_desc`                                          VARCHAR(255),
  `receipttype`                                         VARCHAR(255),
  `data_source_url`                                     VARCHAR(255)     DEFAULT 'https://drive.google.com/drive/folders/10MEskbZAyK6cSAA9GLTb5mInEub39BeC',
  `created_by`                                          VARCHAR(255)      DEFAULT 'Hatri',
  `created_at`                                          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                                          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`                                      BIGINT,
  `deleted`                                             BOOLEAN           DEFAULT 0,
  `md5_hash`                                            VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `md5_hash` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = "The Scrape made by Hatri";
