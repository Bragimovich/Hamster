CREATE TABLE `texas_license_holders`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `holder_name`           VARCHAR(300),
  `license_number`         INT(20),
  `license_type`          VARCHAR(150),
  `license_link`                 VARCHAR(200),
  `status`                 VARCHAR(150),
  `expiration_date`        DATETIME,
  `city`                    VARCHAR(50),
  `state`               VARCHAR(50) ,
  `zip`                 VARCHAR(50) ,
  `county`              VARCHAR(50),

  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

