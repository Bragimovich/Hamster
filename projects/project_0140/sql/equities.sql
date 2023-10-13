create table `public_companies_stock_ft_com_equities`
(
  `id`                   int auto_increment   primary key,
  `equity_name`          VARCHAR(255),
  `equity_url`           VARCHAR(255),
  `equity_symbol`        VARCHAR(255),
  `exchange`             VARCHAR(255),
  `country`              VARCHAR(255),
  `sector`               VARCHAR(255),
  `industry`             VARCHAR(255),
  `data_source_url`      VARCHAR(255),
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted`           tinyint DEFAULT 0,
  UNIQUE KEY `unique_data` (`equity_url`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
