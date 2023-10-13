CREATE TABLE `us_doj_ocdetf_tags`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `tag`             VARCHAR(255),
    `data_source_url` VARCHAR(255)       DEFAULT 'https://www.justice.gov/ocdetf/press-room',
    `created_by`      VARCHAR(255)       DEFAULT 'Igor Sas',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `tag` (`tag`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;