CREATE TABLE `il_dupage_case_pdfs_on_aws`
( 
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`      int,
  `court_id`  int,
  `case_id`  VARCHAR(255) DEFAULT NULL,
  `source_type`     VARCHAR(255) DEFAULT "info",
  `aws_link`     VARCHAR(255) DEFAULT NULL,
  `source_link`     VARCHAR(255) DEFAULT "https://epay.18thjudicial.org/Clerk/caseNumberSearch.do",
  `md5_hash` VARCHAR(255) DEFAULT NULL,
  `created_by`      VARCHAR(255)      DEFAULT 'Tauseeq',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         BOOLEAN           DEFAULT 0,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
