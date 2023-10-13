create table woke_project.irs_non_profit__orgs_country
(
    `id`                       BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `ein`                      VARCHAR(15)        DEFAULT NULL,
    `country`                   VARCHAR(255)       DEFAULT NULL,

    `run_id`                   BIGINT(20),
    `created_by`               VARCHAR(20)        DEFAULT 'Eldar Eminov',
    `created_at`               DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `ein` (`ein`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;