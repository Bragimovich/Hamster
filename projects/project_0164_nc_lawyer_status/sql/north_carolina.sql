create table `north_carolina`
(
  `id`                    INT auto_increment   primary key,
  `name`                  VARCHAR(255),
  `bar_number`            INT,
  `law_firm_name`         VARCHAR(255),
  `law_firm_address`           VARCHAR(255),
  `law_firm_city`           VARCHAR(255),
  `law_firm_state`           VARCHAR(255),
  `law_firm_zip`           VARCHAR(255),
  `judicial_district`     VARCHAR(255),
  `phone`           VARCHAR(255),
  `email`           VARCHAR(255),
  `date_admitted`       date,
  `status_date`       date,
  `sections`           text,
  `status`          VARCHAR(50),
  `run_id`            INT,
  `md5_hash`          VARCHAR(255),
  `link`           VARCHAR(255),
  `data_source_url`           VARCHAR(255),
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
