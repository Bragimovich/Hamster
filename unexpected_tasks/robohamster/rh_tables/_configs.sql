use robohamster;

CREATE TABLE `_configs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `rh_task` int,
    `rh_name` varchar(255),
    `config_yml` TEXT,
    `data_source_url` varchar(511),
    `created_by`      VARCHAR(255)      DEFAULT 'Scraper name',
    `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted`         BOOLEAN           DEFAULT 0,
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The table made by Maxim G for robohamster configs';
