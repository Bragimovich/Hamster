create table `public_companies_stock_ft_com_equities_info`
(
  `id`                   int auto_increment  primary key,
  `equity_symbol`        VARCHAR(255),
  `about`                MEDIUMTEXT,
  `revenue_usd`          VARCHAR(255),
  `net_income_usd`       VARCHAR(255),
  `incorporated_year`    int,
  `employees_count`      VARCHAR(255),
  `location_raw`         text,
  `location_address`     VARCHAR(255),
  `location_city`        VARCHAR(255),
  `location_zip`         VARCHAR(255),
  `phone`                VARCHAR(255),
  `website`              VARCHAR(255),
  `data_source_url`      VARCHAR(255),
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`data_source_url`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
