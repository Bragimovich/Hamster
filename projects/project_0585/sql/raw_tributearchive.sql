CREATE TABLE `raw_tributearchive`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `obituary_id`            BIGINT(20),
  `obituary_description`   TEXT,
  `full_name`              VARCHAR(255),
  `city`                   VARCHAR(255),
  `state`                  VARCHAR(255),
  `birth_date`             DATE,
  `death_date`             DATE,
  `funeral_home_name`      VARCHAR(255),
  `funeral_location_name`  VARCHAR(255),
  `hide_birth_date`        BOOLEAN,
  `hide_death_date`        BOOLEAN,
  `is_published`           BOOLEAN,
  `image_url`              VARCHAR(255),
  `thumbnail_url`          VARCHAR(255),
  `tribute_store_website`  VARCHAR(255),
  `tree_quantity`          VARCHAR(255),
  `forests`                VARCHAR(255),
  `first_name`             VARCHAR(255),
  `last_name`              VARCHAR(255),
  `middle_name`            VARCHAR(255),
  `known_us`               VARCHAR(255),
  `show_captcha`           BOOLEAN,
  `gender`                 BOOLEAN,
  `public_key`             VARCHAR(255),
  `domain_id`              VARCHAR(255),
  `memorial_contributions` TEXT,
  `obituary_was_removed`   BOOLEAN,
  
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