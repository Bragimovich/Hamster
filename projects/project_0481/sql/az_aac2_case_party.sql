create table `az_aac2_case_party`
(
  `id`  int auto_increment   primary key,
  `run_id`  int,
  `court_id`  int,
  `case_id`  varchar (255),
  `is_lawyer`  int,
  `party_name`  varchar (255) DEFAULT NULL,
  `party_type`  varchar (255) DEFAULT NULL,
  `party_law_firm`     varchar (255) DEFAULT NULL,
  `md5_hash`  varchar (255),
  `lower_link`     varchar (350),
  `deleted` int DEFAULT 0,
  `created_by`           VARCHAR(255)       DEFAULT 'Raza',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
