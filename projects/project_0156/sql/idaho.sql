create table `idaho`
(
  `id`                   int auto_increment   primary key,
  `run_id`               int,
  `name`                 VARCHAR(255) DEFAULT NULL,
  `link`                 VARCHAR(255) DEFAULT NULL,
  `law_firm_name`        VARCHAR(255) DEFAULT NULL,
  `law_firm_address`     VARCHAR(255) DEFAULT NULL,
  `law_firm_street`      VARCHAR(255) DEFAULT NULL,
  `law_firm_zip`         VARCHAR(255) DEFAULT NULL,
  `law_firm_county`      VARCHAR(255) DEFAULT NULL,
  `law_firm_state`       VARCHAR(255) DEFAULT NULL,
  `law_firm_city`        VARCHAR(255) DEFAULT NULL,
  `phone`                VARCHAR(255) DEFAULT NULL,
  `fax`                  VARCHAR(255) DEFAULT NULL,
  `email`                VARCHAR(255) DEFAULT NULL,
  `website`              VARCHAR(255) DEFAULT NULL,
  `court_email`          VARCHAR(255) DEFAULT NULL,
  `status`               VARCHAR(255) DEFAULT NULL,
  `registration_status`  VARCHAR(255) DEFAULT NULL,
  `date_admitted`        date DEFAULT NULL,
  `data_source_url`      VARCHAR(255)       DEFAULT 'https://www.ndcourts.gov/lawyers/GetLawyers',
  `md5_hash`             VARCHAR(255),
  `deleted`              int DEFAULT 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Aqeel',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  