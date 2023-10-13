CREATE TABLE `heerf_relief_funds_runs`(
             `id`                   bigint(20) NOT NULL AUTO_INCREMENT,
             `status`               varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT 'processing',
             `created_at`           timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
             `updated_at`           timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
             PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;