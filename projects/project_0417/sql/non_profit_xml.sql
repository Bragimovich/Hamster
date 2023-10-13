CREATE TABLE `non_profit_xml`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),

    `name`            VARCHAR(255)       DEFAULT NULL,
    `total_revenue`   BIGINT             DEFAULT NULL,
    `total_expenses`  BIGINT             DEFAULT NULL,
    `net_assets`      BIGINT             DEFAULT NULL,
    `activity_desc`   TEXT               DEFAULT NULL,
    `mission_desc`    TEXT               DEFAULT NULL,
    `desc_lvl1`       TEXT               DEFAULT NULL,
    `desc_lvl2`       TEXT               DEFAULT NULL,
    `desc_lvl3`       TEXT               DEFAULT NULL,

    `address`         VARCHAR(255)       DEFAULT NULL,
    `state`           VARCHAR(255)       DEFAULT NULL,
    `city`            VARCHAR(255)       DEFAULT NULL,
    `zip`             VARCHAR(255)       DEFAULT NULL,
    `web_url`         VARCHAR(255)       DEFAULT NULL,

    `data_source_url` VARCHAR(255)       DEFAULT NULL,
    `created_by`      VARCHAR(100)       DEFAULT 'Eldar Eminov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted`         BOOLEAN            DEFAULT 0,
    `md5_hash`        VARCHAR(100),
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
