CREATE TABLE `globaldothealth_world_cases`
(
  `id`                      BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
  `run_id`                  BIGINT(20),
  # BEGIN scrape 454
  `case_id`                 BIGINT        NOT NULL,
  `status`                  VARCHAR(30)   NOT NULL,
  `location`                VARCHAR(255),
  `city`                    VARCHAR(255),
  `country`                 VARCHAR(255)  NOT NULL,
  `age`                     VARCHAR(10),
  `gender`                  VARCHAR(10),
  `date_onset`              DATETIME,
  `date_confirmation`       DATETIME,
  `symptoms`                VARCHAR(255),
  `hospitalised`            VARCHAR(1),
  `date_hospitalisation`    DATETIME,
  `isolated`                VARCHAR(1),
  `date_isolation`          DATETIME,
  `outcome`                 VARCHAR(30),
  `contact_comment`         VARCHAR(255),
  `contact_id`              BIGINT,
  `contact_location`        VARCHAR(255),
  `travel_history`          VARCHAR(1),
  `travel_history_entry`    VARCHAR(30),
  `travel_history_start`    VARCHAR(30),
  `travel_history_location` VARCHAR(255),
  `travel_history_country`  VARCHAR(255),
  `genomics_metadata`       VARCHAR(255),
  `confirmation_method`     VARCHAR(100),
  `source`                  VARCHAR(255)  NOT NULL,
  `source_II`               VARCHAR(255),
  `date_entry`              DATETIME      NOT NULL,
  `date_last_modified`      DATETIME      NOT NULL,
  `source_III`              VARCHAR(255),
  `source_IV`               VARCHAR(255),
  `country_code`            VARCHAR(3)    NOT NULL,
  # END
  `data_source_url`         TEXT,
  `created_by`              VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`              DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`          BIGINT,
  `deleted`                 BOOLEAN                DEFAULT 0,
  `md5_hash`                VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT  'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Oleksii Kuts',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
