CREATE TABLE `texas_license_holders_sponsors`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `holder_id`                   INT(20) REFERENCES texas_license_holders (id),
  `role`                        VARCHAR(50),
  `name`                        VARCHAR(100),
  `sponsor_date`                DATETIME,
  `license_number`              INT(20),
  `sponsor_link`                VARCHAR(120),
  `license_type`                VARCHAR(100),
  `expiration_date`             DATETIME,
  `business_address`            VARCHAR(500),
  `business_city_state_zip`     VARCHAR(300),


  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

