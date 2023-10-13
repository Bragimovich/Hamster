
CREATE TABLE `va_finances_receipts` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `run_id` bigint(20) DEFAULT NULL,
  `general_id` bigint(20) DEFAULT NULL,
  `fiscal_year` int(11) DEFAULT NULL,
  `state_sales` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `state_funds` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `federal_funds` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `local_funds` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `other_funds` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `loan_bonds` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `total_receipts` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `balances_bg_year` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `balances_receipts` decimal(20, 2) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `data_source_url` varchar(500) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `created_by` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT 'Frank Rao',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id` bigint(20) DEFAULT NULL,
  `deleted` tinyint(1) DEFAULT '0',
  `md5_hash` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

ALTER TABLE `va_finances_receipts` ALTER COLUMN `created_by` SET DEFAULT 'Frank Rao';
