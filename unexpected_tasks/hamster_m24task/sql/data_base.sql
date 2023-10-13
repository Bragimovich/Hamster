# db02.seo.google_console_data
CREATE TABLE `google_console_data_runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT 'processing',
    `media`           VARCHAR(255) NOT NULL ,
    `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;


CREATE TABLE `google_console_data`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    `name`            VARCHAR(255),
    `url`             VARCHAR(1024),
    `discovered_url`  INT,
    `click_total`      INT,
    `impressions_total` INT,
    `ctr` DOUBLE,
    `position` DOUBLE,
    `start_date`        DATETIME,
    `end_date`          DATETIME,
    `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `md5_hash`         VARCHAR(255),
    INDEX `run_id` (`run_id`),
    INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;


CREATE TABLE `google_console_data_top_pages`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    `site_id`         BIGINT(20),
    `name`            VARCHAR(255),
    `url`             VARCHAR(2048),
    `click_total`      INT,
    `impressions_total` INT,
    `ctr` DOUBLE,
    `position` DOUBLE,
    `start_date`        DATETIME,
    `end_date`          DATETIME,
    # any columns
    `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `md5_hash`         VARCHAR(255),
    INDEX `run_id` (`run_id`),
    INDEX `site_id` (`site_id`),
    INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;



CREATE TABLE `google_console_data_top_queries`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    `site_id`         BIGINT(20),
    `name`            VARCHAR(255),
    `key`             VARCHAR(1024),
    `click_total`      INT,
    `impressions_total` INT,
    `ctr` DOUBLE,
    `position` DOUBLE,
    `start_date`        DATETIME,
    `end_date`          DATETIME,
    # any columns
    `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `md5_hash`         VARCHAR(255),
    INDEX `run_id` (`run_id`),
    INDEX `site_id` (`site_id`),
    INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;