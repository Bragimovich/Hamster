create table `inbar_runs`
(
  `id` int auto_increment primary key,
  `status` VARCHAR(255) DEFAULT 'processing',
  `created_by` VARCHAR(255) DEFAULT 'Tauseeq',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `downloading_completed` boolean default 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `status_idx` (`status`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;