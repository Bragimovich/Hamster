CREATE TABLE `weather_history`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `loc_id`             VARCHAR(100),
    `date`           Datetime,
    `temperature`      DECIMAL(4,2),
    `pressure`           DECIMAL(4,4),
    `day_ind`       VARCHAR(10),


    `data_source_url` VARCHAR(255)     DEFAULT 'https://www.wunderground.com' ,
    `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `md5_hash`        VARCHAR(255),
    UNIQUE KEY `md5` (`md5_hash`),
    UNIQUE KEY `city_date` (`loc_id`, `date`, `day_ind`),
    INDEX `loc_id` (`loc_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
