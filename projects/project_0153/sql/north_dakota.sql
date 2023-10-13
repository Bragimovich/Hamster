create table `north_dakota`
(
  `id`                   int auto_increment   primary key,
  `run_id`               int,
  `bar_number`           VARCHAR(255),
  `name`                 VARCHAR(255),
  `link`                 VARCHAR(255),
  `law_firm_name`        VARCHAR(255),
  `law_firm_address`     VARCHAR(255),
  `law_firm_zip`         VARCHAR(255),
  `law_firm_city`        VARCHAR(255),
  `law_firm_state`       VARCHAR(255),
  `law_firm_county`      VARCHAR(255),
  `law_school`           VARCHAR(255),
  `phone`                VARCHAR(255),
  `email`                VARCHAR(255),
  `registration_status`  VARCHAR(255),
  `date_admitted`        date,
  `data_source_url`      VARCHAR(255)       DEFAULT 'https://www.ndcourts.gov/lawyers/GetLawyers',
  `md5_hash`             VARCHAR(255),
  `deleted`              int DEFAULT 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  