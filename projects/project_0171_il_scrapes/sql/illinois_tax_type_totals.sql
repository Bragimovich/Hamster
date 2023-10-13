use us_sales_taxes;

CREATE TABLE `illinois_tax_type_totals`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `tax_type`                varchar(255)                               null,
  `tax`                     varchar(255)                               null,
  `vendor`                  bigint(20)                               null,
  `warrant`                 float                               null,
  `interest_income`         float                               null,
  `admin_fee`               float                                null,

  `voucher_date`            datetime                                 null,
  `collection_date`         datetime                                 null,

  `data_source_url` VARCHAR(255)       DEFAULT 'https://www2.illinois.gov/rev/localgovernments/disbursements/salesrelated/Pages/Monthly-Archive.aspx',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
