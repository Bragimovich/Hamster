CREATE TABLE `illinois_court_case_numbers`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_number`          varchar(255) DEFAULT NULL,
  `full_last_name` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `role` varchar(255) DEFAULT NULL,
  `birth_date` varchar(255) DEFAULT NULL,
  `legal_status` varchar(255) DEFAULT NULL,
  `search_letter` varchar(2) DEFAULT NULL,
  `page_no`      int,
  `created_by`      VARCHAR(255)      DEFAULT 'Tauseeq',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255) GENERATED ALWAYS AS (md5(CONCAT_WS('',`case_number`,`title`,`role`,`birth_date`,`legal_status`))) STORED,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
