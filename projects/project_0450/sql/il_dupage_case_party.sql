CREATE TABLE `il_dupage_case_party`
( 
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`      int,
  `court_id`  int,
  `case_id`  varchar(255) DEFAULT NULL,
  `party_name`   varchar (255) DEFAULT NULL,
  `party_type`   varchar (255) DEFAULT NULL,
  `law_firm`   varchar (255) DEFAULT NULL,
  `party_address`   varchar (255) DEFAULT NULL,
  `party_city`   varchar (255) DEFAULT NULL,
  `party_state`   varchar (255) DEFAULT NULL,
  `party_zip`   varchar (255) DEFAULT NULL,
  `party_description`   text DEFAULT NULL,
  `md5_hash`        VARCHAR(255),
  `created_by`      VARCHAR(255)      DEFAULT 'Tauseeq',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
