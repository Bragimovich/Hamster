CREATE TABLE `us_sheriffs_info`
(
  `id`                    BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  # BEGIN scrape 1280
  `sheriff`               VARCHAR(255),
  `county`                VARCHAR(255),
  `address1`              VARCHAR(255),
  `address2`              VARCHAR(255),
  `city`                  VARCHAR(255),
  `state`                 VARCHAR(255),
  `zip`                   VARCHAR(255),
  `phone`                 VARCHAR(255),
  `website`               VARCHAR(255),
  # END
  `data_source_url`       VARCHAR(255)           DEFAULT 'https://www.sheriffs.org/about-nsa/map',
  `created_by`            VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`            DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN                DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'sheriffs info from sheriffs.org...., Created by Oleksii Kuts, MultiTask #1280';

CREATE TABLE `us_sheriffs_info__runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT 'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Oleksii Kuts',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'runs for `Investigate sheriffs.org for API and download data to a DB table.`...., Created by Oleksii Kuts, MultiTask #1280';
