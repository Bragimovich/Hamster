
CREATE TABLE `va_enrollment` (
  `id` bigint(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id` bigint(20) DEFAULT NULL,
  `general_id` bigint(20) DEFAULT NULL,
  `school_year` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `subgroup` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `demographic` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `full_time_count` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `part_time_count` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
  `total_count` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
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


