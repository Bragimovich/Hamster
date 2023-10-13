create table `us_senate_financial_disclosures`
(
  `id`                   int auto_increment   primary key,
  `full_name`            varchar(255),
  `first_name`           varchar(255),
  `middle_name`          varchar(255),
  `last_name`            varchar(255),
  `office`               varchar(255),
  `filer_type`           varchar(255),
  `report_type`          varchar(255),
  `date_received_filed`  date,
  `transaction_date`     date,
  `owner`                varchar(255),
  `ticker`               varchar(255),
  `asset_name`           varchar(255),
  `asset_type`           varchar(255),
  `type`                 varchar(255),
  `amount`               varchar(255),
  `comments`             varchar(255),
  `data_source_url`      varchar(255),
  `run_id`               int,
  `last_scrape_date`     date,
  `next_scrape_date`     date,
  `md5_hash`             varchar(100) GENERATED ALWAYS AS (md5(concat_ws(_utf8mb4'',`full_name`,`office`,`filer_type`,`report_type`,  CAST(date_received_filed as CHAR), CAST(transaction_date as CHAR), `owner`, `ticker`, `asset_name`, `asset_type`, `type`, `amount`, `comments`, `data_source_url`))) STORED
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `scrape_frequency`     VARCHAR(255)       DEFAULT 'Daily',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`       BIGINT,
  `deleted`              tinyint(1) DEFAULT 0,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
