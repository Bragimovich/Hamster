CREATE TABLE `il_dupage_case_info`
( 
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`      int,
  `court_id`  int,
  `case_id`  varchar(255) DEFAULT NULL,
  `case_name`  text DEFAULT NULL,
  `case_filed_date`  varchar(255) DEFAULT NULL,
  `case_type`  varchar(255) DEFAULT NULL,
  `case_description`  varchar(255) DEFAULT NULL,
  `disposition_or_status`  varchar(255) DEFAULT NULL,
  `status_as_of_date`  varchar(255) DEFAULT NULL,
  `judge_name`  varchar(255) DEFAULT NULL,
  `md5_hash`        VARCHAR(255),
  `created_by`      VARCHAR(255)      DEFAULT 'Tauseeq',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
