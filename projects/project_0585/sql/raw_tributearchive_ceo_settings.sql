CREATE TABLE `raw_tributearchive_ceo_settings`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `obituary_id`     BIGINT(20),
  `image_url`       VARCHAR(255),
  `og_image_widh`   BIGINT(20),
  `og_image_height` BIGINT(20),
  `og_url`          VARCHAR(255),
  `description`     TEXT,
  `google_plus_account_url` VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255)      NOT NULL,
  UNIQUE KEY `obituary` (`obituary_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';
