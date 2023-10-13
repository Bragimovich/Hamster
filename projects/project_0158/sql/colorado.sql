create table `colorado`
(
  `id`                   int auto_increment   primary key,
  `run_id`               int,
  `name`                 VARCHAR(255) DEFAULT NULL,
  `first_name`           VARCHAR(255) DEFAULT NULL,
  `middle_name`          VARCHAR(255) DEFAULT NULL,
  `last_name`            VARCHAR(255) DEFAULT NULL,
  `bar_number`           VARCHAR(255) DEFAULT NULL,
  `link`                 VARCHAR(255) DEFAULT NULL,
  `law_firm_name`        VARCHAR(255) DEFAULT NULL,
  `law_firm_address`     VARCHAR(255) DEFAULT NULL,
  `law_firm_city`        VARCHAR(255) DEFAULT NULL,
  `law_firm_zip`         VARCHAR(255) DEFAULT NULL,
  `law_firm_state`       VARCHAR(255) DEFAULT NULL,
  `phone`                VARCHAR(255) DEFAULT NULL,
  `fax`                  VARCHAR(255) DEFAULT NULL,
  `email`                VARCHAR(255) DEFAULT NULL,
  `private_practice`     BOOLEAN DEFAULT 0,
  `professional_liability_insurance`  BOOLEAN DEFAULT 0,
  `date_admitted`        Date, 
  `registration_status`  VARCHAR(255),
  `md5_hash`             VARCHAR(255),
  `disciplinary_history` JSON DEFAULT NULL,
  `deleted`              int DEFAULT 0,
  `scrape_frequency`     VARCHAR(50)        DEFAULT 'daily',
  `created_by`           VARCHAR(50)       DEFAULT 'Adeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  