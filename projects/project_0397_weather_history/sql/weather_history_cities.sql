CREATE TABLE `weather_history_cities`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `city`               VARCHAR(255),
    `loc_id`             VARCHAR(100),
    `state`           VARCHAR(255),
    `state_code`      VARCHAR(10),
    `country_code`       VARCHAR(10),
    `latitude`           DECIMAL(4,4),
    `longitude`          DECIMAL(4,4),
    `placeId`            VARCHAR(255),
    `postal_code`        VARCHAR(50),
    `search_link`        VARCHAR(511),

    `data_source_url` VARCHAR(255)     DEFAULT 'https://www.wunderground.com' ,
    `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `md5_hash`        VARCHAR(255),
    UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
