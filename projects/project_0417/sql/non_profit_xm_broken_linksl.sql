CREATE TABLE `non_profit_xml__broken_links`
(
    `id`                   BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`               BIGINT(20),

    `name`                 VARCHAR(255)       DEFAULT NULL,
    `organization`         VARCHAR(255)       DEFAULT NULL,
    `total_annual_salary`  BIGINT(20)         DEFAULT NULL,
    `broken_link`          VARCHAR(255)       DEFAULT NULL,

    `created_by`           VARCHAR(100)       DEFAULT 'Eldar Eminov',
    `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `md5_hash`        VARCHAR(100),
    UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
