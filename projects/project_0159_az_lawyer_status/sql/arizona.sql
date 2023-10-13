create table `arizona`
(
  `id`                   int auto_increment   primary key,
  `name`           VARCHAR(255),
  `law_firm_name`           VARCHAR(255),
  `law_firm_address`           VARCHAR(255),
  `law_firm_county`           VARCHAR(255),
  `law_firm_state`           VARCHAR(255),
  `phone`           VARCHAR(255),
  `email`           VARCHAR(255),
  `type`           VARCHAR(255),
  `registration_status`   VARCHAR(255),
  `date_admitted`       date,
  `sections`           text,
  `link`           VARCHAR(255),
  `data_source_url`           VARCHAR(255),
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`link`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  
  