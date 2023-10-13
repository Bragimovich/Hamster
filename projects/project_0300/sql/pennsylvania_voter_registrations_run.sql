CREATE TABLE `pennsylvania_voter_registrations_run` 
(
  `id` bigint NOT NULL AUTO_INCREMENT,
  `status` varchar(50) DEFAULT 'Processing',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET = `utf8mb4`
 COLLATE = utf8mb4_unicode_520_ci;
