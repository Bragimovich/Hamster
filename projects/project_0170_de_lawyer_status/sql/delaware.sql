create table `delaware`
(
  `id`                   int auto_increment   primary key,
  `name`                 VARCHAR(255),
  `bar_number`           VARCHAR(255),
  `link`                 VARCHAR(255) DEFAULT 'https://rp470541.doelegal.com/vwPublicSearch/Show-VwPublicSearch-Table.aspx',
  `law_firm_name`        VARCHAR(255),
  `law_firm_address`     VARCHAR(255),
  `law_firm_city`        VARCHAR(255),
  `law_firm_zip`         VARCHAR(255),
  `law_firm_state`       VARCHAR(255),
  `phone`                VARCHAR(255),
  `date_admitted`        Date, 
  `registration_status`  VARCHAR(255),
  `md5_hash`             VARCHAR(255),
  `run_id`               VARCHAR(255),
  `is_deleted`           tinyint(1) DEFAULT 0,
  `scrape_frequency`     VARCHAR(50)        DEFAULT 'daily',
  `created_by`           VARCHAR(50)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
