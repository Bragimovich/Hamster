CREATE TABLE `texas_license_holders_alternate_names`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `holder_id`               INT(20) REFERENCES texas_license_holders (id),
  `alternate_name`          VARCHAR(150),

  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

